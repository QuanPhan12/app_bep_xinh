import '../../../core/services/firestore_user_store.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_repository.dart';
import '../models/meal_session.dart';
import 'meal_ingredients.dart';

abstract interface class MealActionsRepository {
  Future<void> complete(String mealId);
  Future<void> consume(String mealId, List<PantryDeduction> deductions);
}

class FirestoreMealActionsRepository implements MealActionsRepository {
  final FirestoreUserStore store;
  const FirestoreMealActionsRepository(this.store);
  @override
  Future<void> complete(String mealId) async {
    store.checkSession();
    final ref = store.account
        .collection('meal_sessions')
        .doc(kitchenKey(mealId));
    await store.firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      store.checkSession();
      if (!snapshot.exists) {
        throw const FormatException('Hãy bắt đầu nấu bữa trước.');
      }
      final session = MealSession.fromJson(mealId, snapshot.data()!);
      if (session.completed) return;
      if (session.done.length != session.plan.dishes.length) {
        throw const FormatException('Còn món chưa hoàn tất.');
      }
      // Nhật ký dùng ID ổn định và ghi cùng phiên: thử lại không nhân đôi lịch sử.
      for (final dish in session.plan.dishes) {
        final log = CookingLog(
          id: mealKey('$mealId/${dish.recipe.id}'),
          recipe: dish.recipe,
          day: dateKey(DateTime.now()),
          servings: session.plan.servings,
          note: 'Nấu trong bữa: ${session.plan.displayName}',
        );
        tx.set(
          store.account.collection('cooking_logs').doc(log.id),
          kitchenDocumentData(log),
        );
      }
      tx.set(ref, kitchenDocumentData(session.copyWith(completed: true)));
    });
    store.checkSession();
  }

  @override
  Future<void> consume(String mealId, List<PantryDeduction> deductions) async {
    if (deductions.isEmpty) {
      throw const FormatException('Không có lượng tồn kho phù hợp để trừ.');
    }
    if (deductions.length > 180 ||
        deductions.map((d) => d.lot.id).toSet().length != deductions.length) {
      throw const FormatException('Danh sách trừ kho không hợp lệ.');
    }
    store.checkSession();
    final ref = store.account
        .collection('meal_sessions')
        .doc(kitchenKey(mealId));
    await store.firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      store.checkSession();
      if (!snapshot.exists) {
        throw const FormatException('Không tìm thấy phiên nấu.');
      }
      final session = MealSession.fromJson(mealId, snapshot.data()!);
      if (session.pantryConsumed) return;
      if (!session.completed) {
        throw const FormatException('Hoàn tất bữa ăn trước khi trừ kho.');
      }
      final next = <PantryLot>[];
      // Đọc tất cả trước khi ghi để bảo vệ giao dịch khi kho đổi ở thiết bị khác.
      for (final deduction in deductions) {
        final lotRef = store.account
            .collection('pantry_lots')
            .doc(kitchenKey(deduction.lot.id));
        final current = await tx.get(lotRef);
        if (!current.exists) {
          throw const FormatException('Kho đã thay đổi. Hãy tải lại.');
        }
        final lot = PantryLot.fromJson(current.id, current.data()!);
        if (lot.amount != deduction.lot.amount ||
            lot.unitId != deduction.lot.unitId ||
            lot.ingredientId != deduction.lot.ingredientId ||
            lot.expiresOn != deduction.lot.expiresOn ||
            lot.amount == null ||
            lot.isExpired(DateTime.now()) ||
            !deduction.amount.isFinite ||
            deduction.amount <= 0 ||
            deduction.amount > lot.amount!) {
          throw const FormatException(
            'Kho đã thay đổi. Hãy kiểm tra lại lượng cần trừ.',
          );
        }
        next.add(lot.withAmount(lot.amount! - deduction.amount));
      }
      store.checkSession();
      for (final lot in next) {
        tx.set(
          store.account.collection('pantry_lots').doc(lot.id),
          kitchenDocumentData(lot),
        );
      }
      tx.set(ref, kitchenDocumentData(session.copyWith(pantryConsumed: true)));
    });
    store.checkSession();
  }
}
