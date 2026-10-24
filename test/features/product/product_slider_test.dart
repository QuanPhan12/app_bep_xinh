import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/features/product/widgets/product_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../support/mock_services.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  setUp(AppTapHandler.resetLock);

  testWidgets(
    'tablet next arrow goes through one tap handler and reaches next page',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: const [
              Breakpoint(start: 0, end: 599, name: MOBILE),
              Breakpoint(start: 600, end: double.infinity, name: TABLET),
            ],
            child: child!,
          ),
          home: Scaffold(body: ProductSlider(recipes: homeFixture().recipes)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        0,
      );
      await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
