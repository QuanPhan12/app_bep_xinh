import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/utils/async_serial_queue.dart';
import '../../ingredients/models/ingredient_catalog.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_local_storage.dart';
import '../../recipe_detail/models/recipe_detail.dart';

class OfflineRecipe {
  final RecipeDetail recipe;
  final DateTime savedAt;
  const OfflineRecipe(this.recipe, this.savedAt);
  Map<String, dynamic> toJson() => {
    'recipe': {
      ...recipe.content.toJson(),
      'id': recipe.id,
      'author': {
        'id': recipe.author.id ?? 'legacy',
        'name': recipe.author.name,
        'handle': recipe.author.handle,
      },
      'isFavorite': false,
    },
    'units': {
      for (final item in recipe.ingredients)
        if (item.unit != null)
          item.unit!.id: {
            'id': item.unit!.id,
            'label': item.unit!.label,
            'type': item.unit!.type,
          },
    },
    'savedAt': savedAt.toUtc().toIso8601String(),
  };
  factory OfflineRecipe.fromJson(Map<String, dynamic> json) {
    final content = Map<String, dynamic>.from(json['recipe'] as Map);
    final units = Map<String, dynamic>.from(json['units'] as Map).values
        .map(
          (e) => IngredientUnit.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    final ingredients = <String, Ingredient>{};
    for (final raw in content['ingredients'] as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      final id = item['ingredientId'] as String?;
      if (id != null) {
        ingredients[id] = Ingredient(
          id: id,
          name: item['name'] as String,
          group: 'offline',
          unitIds: {
            ...?ingredients[id]?.unitIds,
            if (item['unitId'] != null) item['unitId'] as String,
          }.toList(),
        );
      }
    }
    return OfflineRecipe(
      RecipeDetail.fromJson(
        content,
        IngredientCatalog(
          ingredients: ingredients.values.toList(),
          units: units,
        ),
      ),
      DateTime.parse(json['savedAt'] as String),
    );
  }
}

class OfflineRecipeService {
  static const maxBytes = 2 * 1024 * 1024;
  final KitchenLocalStorage storage;
  final String storageKey;
  final void Function() checkSession;
  final Future<bool> Function(String) isPublished;
  final http.Client client;
  final AsyncSerialQueue _writes = AsyncSerialQueue();
  OfflineRecipeService({
    required this.storage,
    required this.storageKey,
    required this.checkSession,
    required this.isPublished,
    required this.client,
  });
  Future<List<OfflineRecipe>> list() async {
    checkSession();
    final raw = await storage.read(storageKey);
    checkSession();
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => OfflineRecipe.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist(List<OfflineRecipe> items) async {
    checkSession();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    if (utf8.encode(raw).length > maxBytes) {
      throw const FormatException(
        'Bộ nhớ tải về đã đầy. Xóa bớt món rồi thử lại.',
      );
    }
    await storage.write(storageKey, raw);
    checkSession();
  }

  Future<RecipeImage?> _image(RecipeImage? image) async {
    if (image == null) return null;
    if (image.bytes != null) return image;
    // Ảnh trong bundle đã có sẵn khi mất mạng, giữ tham chiếu để không tốn thêm dung lượng cache.
    if (image.assetPath != null) return image;
    final uri = Uri.parse(image.url!);
    if (uri.scheme != 'https' ||
        uri.host != 'res.cloudinary.com' ||
        !uri.path.startsWith('/ddqouziau/image/upload/')) {
      throw const FormatException('Nguồn ảnh không được hỗ trợ.');
    }
    final optimized = uri.replace(
      path: uri.path.replaceFirst(
        '/image/upload/',
        '/image/upload/w_720,q_65,f_jpg/',
      ),
    );
    final response = await client
        .send(http.Request('GET', optimized))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw StateError('Không tải được ảnh.');
    final builder = BytesBuilder();
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      builder.add(chunk);
      if (builder.length > 800000) {
        throw const FormatException('Ảnh quá lớn để tải offline.');
      }
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty || bytes.length > 800000) {
      throw const FormatException('Ảnh tải về không hợp lệ hoặc quá lớn.');
    }
    return RecipeImage.memory(id: image.id, name: image.name, bytes: bytes);
  }

  Future<void> download(RecipeDetail recipe) => _writes.run(() async {
    checkSession();
    if (!await isPublished(recipe.id)) {
      throw StateError('Công thức không còn công khai.');
    }
    final json = recipe.content.toJson();
    json['cover'] = (await _image(recipe.cover))?.toJson();
    if (recipe.content.photos.isNotEmpty) {
      json['photos'] = [
        for (final photo in recipe.content.photos)
          (await _image(photo))!.toJson(),
      ];
    }
    final steps = <Map<String, dynamic>>[];
    for (final step in recipe.steps) {
      final item = step.toJson();
      item['photo'] = (await _image(step.photo))?.toJson();
      steps.add(item);
    }
    json['steps'] = steps;
    final original = OfflineRecipe(recipe, DateTime.now()).toJson();
    original['recipe'] = {
      ...original['recipe'] as Map<String, dynamic>,
      ...json,
    };
    final cached = OfflineRecipe.fromJson(original);
    // Kiểm tra lại trước khi ghi để không giữ bài đã bị gỡ trong lúc tải ảnh.
    if (!await isPublished(recipe.id)) {
      throw StateError('Công thức không còn công khai.');
    }
    final current = await list();
    await _persist([...current.where((e) => e.recipe.id != recipe.id), cached]);
  });
  Future<void> remove(String id) => _writes.run(
    () async =>
        _persist((await list()).where((e) => e.recipe.id != id).toList()),
  );
  Future<void> clear() async {
    await _writes.settled;
    await storage.remove(storageKey);
  }

  Future<bool> verify(String id) => isPublished(kitchenKey(id));
}
