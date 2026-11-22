import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/features/recipe_detail/widgets/recipe_detail_more_menu.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/recipe_reports/services/recipe_report_repository.dart';

import '../../support/recipe_detail_fakes.dart';
import '../../support/kitchen_fakes.dart';
import '../../support/auth_fake.dart';

class _Reports implements RecipeReportRepository {
  @override
  Future<OwnRecipeReport?> own(String id) async => null;
  @override
  Future<void> submit(String id, String category, String reason) async {}
}

void main() {
  setUp(() {
    configureAuthenticatedTaps();
    AppTapHandler.resetLock();
  });
  Future<void> open(
    WidgetTester tester, {
    String author = 'other',
    bool saving = false,
    VoidCallback? toggle,
  }) async {
    final kitchen = kitchenFixture(reports: _Reports());
    addTearDown(() => disposeKitchen(kitchen));
    await tester.pumpWidget(
      KitchenScope(
        services: kitchen,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              actions: [
                RecipeDetailMoreMenu(
                  recipe: RecipeDetail(
                    id: 'r_more',
                    content: detailFixture().content,
                    author: RecipeAuthor(id: author, name: 'Tác giả'),
                    contentHash: List.filled(64, 'a').join(),
                  ),
                  isFavorite: false,
                  savingFavorite: saving,
                  servings: 4,
                  onToggleFavorite: toggle ?? () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsOneWidget);
    await tester.tap(find.byTooltip('Tùy chọn công thức'));
    await tester.pumpAndSettle();
  }

  testWidgets('one More contains save, remix and working report action', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Lưu món'), findsOneWidget);
    expect(find.text('Biến tấu công thức'), findsOneWidget);
    expect(find.text('Báo cáo món'), findsOneWidget);
    await tester.tap(find.text('Báo cáo món'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('own recipe hides report and in-flight save stays disabled', (
    tester,
  ) async {
    var saves = 0;
    await open(tester, author: 'alice', saving: true, toggle: () => saves++);
    expect(find.text('Báo cáo món'), findsNothing);
    final item = find
        .ancestor(
          of: find.text('Đang lưu…'),
          matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
        )
        .first;
    expect(tester.widget<PopupMenuItem>(item).enabled, false);
    await tester.tap(find.text('Đang lưu…'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'More opens recipe tools with selected servings and releases tap lock',
    (tester) async {
      await open(tester);
      for (final label in [
        'Chia sẻ',
        'Sao chép liên kết',
        'Thêm vào thực đơn',
        'Bộ sưu tập',
        'Tải xuống',
        'Đánh giá cộng đồng',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Thêm vào thực đơn'));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      expect(AppTapHandler.isBusy, isFalse);
      AppTapHandler.resetLock();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Số người ăn'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
