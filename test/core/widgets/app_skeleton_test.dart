import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({bool disabled = false, bool visible = true}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disabled),
      child: TickerMode(
        enabled: visible,
        child: const Scaffold(
          body: AppSkeleton(child: SkeletonBlock(height: 100, width: 200)),
        ),
      ),
    ),
  );

  testWidgets(
    'skeleton is accessible and stops for reduced motion or hidden routes',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host());
      expect(find.bySemanticsLabel('Đang tải'), findsOneWidget);
      semantics.dispose();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(host(disabled: true));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(host(visible: false));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shimmer pauses in background and resumes without leaking its ticker',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(host());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
