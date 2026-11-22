import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/kitchen/widgets/kitchen_today_overview.dart';

import '../../support/kitchen_fakes.dart';

void main() {
  testWidgets(
    'Kitchen overview follows actual meal changes and ignores past entries',
    (tester) async {
      final services = kitchenFixture();
      addTearDown(() => disposeKitchen(services));
      final today = DateTime.now();
      MealPlanEntry meal(
        String id,
        String title,
        DateTime day,
        MealSlot slot,
      ) => MealPlanEntry(
        id: id,
        day: dateKey(day),
        slot: slot,
        recipe: RecipeRef(id: 'r_$id', title: title, authorId: 'alice'),
        servings: 2,
      );
      await services.meals.save(
        meal(
          'past',
          'Món hôm qua',
          today.subtract(const Duration(days: 1)),
          MealSlot.breakfast,
        ),
      );
      await services.meals.save(
        meal(
          'future',
          'Món ngày mai',
          today.add(const Duration(days: 1)),
          MealSlot.lunch,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: KitchenScope(
              services: services,
              child: const KitchenTodayOverview(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Món ngày mai'), findsOneWidget);
      expect(find.text('Món hôm qua'), findsNothing);
      await services.meals.save(
        meal('today', 'Món hôm nay', today, MealSlot.dinner),
      );
      await tester.pumpAndSettle();
      expect(find.text('Món hôm nay'), findsOneWidget);
      expect(find.text('Món ngày mai'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Kitchen overview shows an honest empty state and only actual timers',
    (tester) async {
      final services = kitchenFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: KitchenScope(
              services: services,
              child: const KitchenTodayOverview(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay bạn muốn nấu gì?'), findsOneWidget);
      expect(find.textContaining('đồng hồ đang theo dõi'), findsNothing);
      await services.timers.start('Luộc trứng', const Duration(minutes: 5));
      await tester.pump();
      expect(find.text('1 đồng hồ đang theo dõi'), findsOneWidget);
      expect(find.text('Luộc trứng'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await disposeKitchen(services);
    },
  );
}
