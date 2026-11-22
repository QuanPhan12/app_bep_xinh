import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../ingredients/models/ingredient_catalog.dart';

enum PantryFilter { all, soon, expired }

class PantryCubit extends KitchenListCubit<PantryLot> {
  final KitchenServices services;
  IngredientCatalog? catalog;
  PantryFilter filter = PantryFilter.all;
  PantryCubit(this.services) : super(services.pantry);
  Future<IngredientCatalog> loadCatalog() async =>
      catalog ??= await services.catalog.fetchCatalog();
  void select(PantryFilter value) {
    filter = value;
    emit(
      KitchenListState(
        items: state.items,
        loading: state.loading,
        busy: state.busy,
      ),
    );
  }

  List<PantryLot> get visible {
    final today = DateTime.now();
    final items = state.items
        .where(
          (lot) => switch (filter) {
            PantryFilter.all => true,
            PantryFilter.soon =>
              (lot.amount == null || lot.amount! > 0) && lot.isSoon(today),
            PantryFilter.expired => lot.isExpired(today),
          },
        )
        .toList();
    items.sort(
      (a, b) => (a.expiresOn ?? '9999').compareTo(b.expiresOn ?? '9999'),
    );
    return items;
  }

  Future<bool> importSelected() => run(() async {
    final fridge = await services.fridge.fetchFridge();
    final catalog = await loadCatalog();
    final known = state.items.map((e) => e.ingredientId).toSet();
    for (final id in fridge.selectedIds) {
      if (known.contains(id)) continue;
      final ingredient = catalog.byId[id];
      if (ingredient == null) continue;
      await repository.save(
        PantryLot(
          id: 'import_${sha256.convert(utf8.encode(id)).toString().substring(0, 32)}',
          ingredientId: id,
          name: ingredient.name,
        ),
      );
    }
  });
  Future<bool> consume(String id, double amount) => update(id, (current) {
    if (!amount.isFinite ||
        amount <= 0 ||
        current.amount == null ||
        amount > current.amount!) {
      throw const FormatException(
        'Lượng dùng vượt tồn kho hiện tại. Hãy tải lại.',
      );
    }
    return current.withAmount(current.amount! - amount);
  });
}
