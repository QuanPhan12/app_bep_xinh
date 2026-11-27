import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_bep_xinh/features/nutrition/models/nutrition.dart';
import 'package:app_bep_xinh/features/nutrition/services/nutrition_repository.dart';
import 'package:app_bep_xinh/features/nutrition/services/nutrition_photo_picker.dart';
import 'package:app_bep_xinh/features/nutrition/services/nutrition_ai_store.dart';

import 'kitchen_fakes.dart';

NutritionCatalog? _catalog;
NutritionCatalog nutritionCatalogFixture() =>
    _catalog ??= NutritionCatalog.fromJson(
      jsonDecode(
        File('assets/nutrition/usda_sr_legacy.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );

class FakeNutritionRepository implements NutritionRepository {
  @override
  final MemoryKitchenRepository<NutritionEntry> journal =
      MemoryKitchenRepository<NutritionEntry>();
  @override
  Future<NutritionCatalog> catalog() async => nutritionCatalogFixture();
  Future<List<NutritionLine>> Function(List<NutritionLine>)? onRecognize;
  @override
  Future<List<NutritionLine>> recognize({
    required String id,
    required String text,
    required NutritionCatalog catalog,
    List<NutritionLine> ingredients = const [],
    Uint8List? image,
  }) async => onRecognize?.call(ingredients) ?? ingredients;
}

class FakeNutritionPhotos implements NutritionPhotoPicker {
  Uint8List? result;
  @override
  Future<Uint8List?> pick({bool camera = false}) async => result;
}

class FakeNutritionJobs implements NutritionAiStore {
  String? cached;
  int reserved = 0, completed = 0, failed = 0;
  @override
  Future<NutritionLease> reserve(String id, String digest, int limit) async {
    reserved++;
    return NutritionLease(1, cached);
  }

  @override
  Future<void> finish(String id, int lease, String? result) async {
    if (result == null) {
      failed++;
    } else {
      completed++;
      cached = result;
    }
  }
}
