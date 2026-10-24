import 'package:app_bep_xinh/features/home/widgets/home_banner.dart';
import 'package:app_bep_xinh/features/home/widgets/home_banner_sliver.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../support/mock_services.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);

  CarouselSlider carousel(WidgetTester tester, {bool offstage = false}) =>
      tester.widget<CarouselSlider>(
        find.byType(CarouselSlider, skipOffstage: !offstage),
      );

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'autoplay pauses for visibility, ticker mode, accessibility and app lifecycle',
    (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var visible = true;
      var tickers = true;
      var reduced = false;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduced),
                child: TickerMode(
                  enabled: tickers,
                  child: HomeBanner(
                    banners: homeFixture().banners,
                    isVisible: visible,
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(carousel(tester).options.autoPlay, isTrue);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      final page = tester
          .widget<AnimatedSmoothIndicator>(find.byType(AnimatedSmoothIndicator))
          .activeIndex;
      expect(page, 1);

      update(() => visible = false);
      await tester.pump();
      expect(carousel(tester).options.autoPlay, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        page,
      );
      update(() {
        visible = true;
        tickers = false;
      });
      await tester.pump();
      expect(carousel(tester).options.autoPlay, isFalse);
      update(() {
        tickers = true;
        reduced = true;
      });
      await tester.pump();
      expect(carousel(tester).options.autoPlay, isFalse);
      update(() => reduced = false);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        page,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(carousel(tester).options.autoPlay, isTrue);
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        page,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('touch and a covering route pause playback, then resume it', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(host(HomeBanner(banners: homeFixture().banners)));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CarouselSlider)),
    );
    await tester.pump();
    expect(carousel(tester).options.autoPlay, isFalse);
    await gesture.up();
    await tester.pump();
    expect(carousel(tester).options.autoPlay, isTrue);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Detail'))),
    );
    await tester.pumpAndSettle();
    expect(carousel(tester, offstage: true).options.autoPlay, isFalse);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(carousel(tester).options.autoPlay, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh preserves page identity, handles reordered, single and empty responses',
    (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      var items = homeFixture().banners;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return HomeBanner(banners: items, isVisible: false);
            },
          ),
        ),
      );
      final original = tester.state<CarouselSliderState>(
        find.byType(CarouselSlider),
      );
      original.carouselController.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        2,
      );
      update(() => items = homeFixture().banners);
      await tester.pump();
      expect(
        identical(tester.state(find.byType(CarouselSlider)), original),
        isTrue,
      );
      update(() => items = [items.last, items.first]);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedSmoothIndicator>(
              find.byType(AnimatedSmoothIndicator),
            )
            .activeIndex,
        0,
      );
      update(() => items = [items.first]);
      await tester.pumpAndSettle();
      expect(carousel(tester).options.autoPlay, isFalse);
      expect(find.byType(AnimatedSmoothIndicator), findsNothing);
      update(() => items = []);
      await tester.pumpAndSettle();
      expect(find.byType(CarouselSlider), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sliver disables autoplay after scrolling past the banner', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      host(
        CustomScrollView(
          slivers: [
            HomeBannerSliver(banners: homeFixture().banners),
            const SliverToBoxAdapter(child: SizedBox(height: 2500)),
          ],
        ),
      ),
    );
    expect(carousel(tester).options.autoPlay, isTrue);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(carousel(tester, offstage: true).options.autoPlay, isFalse);
    expect(tester.takeException(), isNull);
  });
}
