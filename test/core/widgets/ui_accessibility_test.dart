import 'package:app_bep_xinh/sollume/shared/app_loading_indicator.dart';

import 'dart:math' as math;

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);

  test('action and secondary text meet normal text contrast', () {
    for (final pair in [
      (AppColors.textWhite, AppColors.action),
      (AppColors.textSecondary, AppColors.background),
      (AppColors.textTertiary, AppColors.surface),
      (AppColors.secondary, AppColors.secondaryLight),
    ]) {
      final first = pair.$1.computeLuminance();
      final second = pair.$2.computeLuminance();
      final ratio =
          (math.max(first, second) + .05) / (math.min(first, second) + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets(
    'primary action wraps large text and keeps its label while loading',
    (tester) async {
      var loading = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: SizedBox(
                  width: 180,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      update = setState;
                      return AppButton(
                        text: 'Gửi công thức chờ duyệt',
                        icon: Icons.send,
                        isLoading: loading,
                        onPressed: () {},
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThan(48));
      expect(find.byType(FittedBox), findsNothing);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(tester.takeException(), isNull);
      update(() => loading = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Gửi công thức chờ duyệt'), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
