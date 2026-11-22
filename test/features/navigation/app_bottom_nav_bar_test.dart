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
    expect(
      tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentIndex,
      0,
    );
    pending.complete();
    await task;
    expect(tester.takeException(), isNull);
  });
}
