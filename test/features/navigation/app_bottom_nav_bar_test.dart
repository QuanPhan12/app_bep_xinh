import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/features/navigation/widgets/app_bottom_nav_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  setUp(AppTapHandler.resetLock);

  testWidgets(
    'center action keeps all four shell tab indices at narrow width',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selected = <int>[];
      var creates = 0;
      for (var index = 0; index < 4; index++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AppBottomNavBar(
                currentIndex: index,
                onTabSelected: selected.add,
                onCreateRecipe: () => creates++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.destinations, hasLength(5));
        expect(bar.selectedIndex, index < 2 ? index : index + 1);
        final center = tester.getCenter(
          find.byKey(const ValueKey('nav_create_recipe')),
        );
        expect(center.dx, 160);
        final action = find.descendant(
          of: find.byKey(const ValueKey('nav_create_recipe')),
          matching: find.byType(IconButton),
        );
        final barTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
        expect(tester.getCenter(action).dy, barTop + 40);
        expect(find.byTooltip('Đăng món'), findsOneWidget);
        expect(find.text('Đăng món'), findsNothing);
        await tester.tap(find.byKey(ValueKey('nav_item_$index')));
        await tester.pumpAndSettle();
        AppTapHandler.resetLock();
      }
      expect(selected, [0, 1, 2, 3]);
      await tester.tap(find.byKey(const ValueKey('nav_create_recipe')));
      await tester.pumpAndSettle();
      expect(creates, 1);
      expect(selected, [0, 1, 2, 3]);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a blocked navigation tap keeps the selected shell tab', (
    tester,
  ) async {
    var switches = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: AppColors.lightColorScheme),
        home: Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 0,
            onTabSelected: (_) => switches++,
            onCreateRecipe: () => switches++,
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(AppBottomNavBar));
    final pending = Completer<void>();
    final task = AppTapHandler.handle(
      context,
      actionName: 'pending_write',
      enableHaptic: false,
      onTap: () => pending.future,
    );
    await tester.pump();
    expect(AppTapHandler.isBusy, isTrue);
    await tester.tap(find.byKey(const ValueKey('nav_item_3')));
    await tester.pumpAndSettle();
    expect(switches, 0);
    await tester.tap(find.byKey(const ValueKey('nav_create_recipe')));
    await tester.pumpAndSettle();
    expect(switches, 0);
    expect(
      tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentIndex,
      0,
    );
    pending.complete();
    await task;
    expect(tester.takeException(), isNull);
  });
}
