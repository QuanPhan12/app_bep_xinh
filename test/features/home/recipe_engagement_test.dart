import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/home/widgets/home_feed_view.dart';
import 'package:app_bep_xinh/features/home/widgets/post_action.dart';
import 'package:app_bep_xinh/features/home/widgets/post_comment_action.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/recipe_reviews/services/recipe_review_repository.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_fake.dart';
import '../../support/mock_services.dart';
import '../../support/test_text_styles.dart';
import '../../support/kitchen_fakes.dart';

class _LiveReviews extends FakeKitchenReviews {
  final controller = StreamController<RatingSummary>.broadcast();
  @override
  Stream<RatingSummary> ratings(String recipeId) => controller.stream;
}

void main() {
  setUpAll(configureTestTextStyles);
  setUp(configureAuthenticatedTaps);
  setUp(AppTapHandler.resetLock);
  testWidgets('comment count follows approved summary and cancels on dispose', (
    tester,
  ) async {
    final reviews = _LiveReviews();
    final kitchen = kitchenFixture(reviews: reviews);
    addTearDown(() => disposeKitchen(kitchen));
    addTearDown(reviews.controller.close);
    await tester.pumpWidget(
      KitchenScope(
        services: kitchen,
        child: MaterialApp(
          home: Scaffold(
            body: PostCommentAction(
              recipeId: 'r_live',
              fallbackCount: 99,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('—'), findsOneWidget);
    reviews.controller.add(const RatingSummary(count: 7, sum: 30));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    reviews.controller.addError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    reviews.controller.add(const RatingSummary(count: 2, sum: 8));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(reviews.controller.hasListener, isFalse);
    expect(tester.takeException(), isNull);
  });
  test('server counters decode, survive favorite changes and reject invalid numbers', () {
    final json = Map<String, dynamic>.from(
      (fixtureJson('recipe_details')['recipes'] as List).first as Map,
    );
    final item = RecipeItem.fromRecipeJson({
      ...json,
      'engagement': {'likeCount': 12, 'commentCount': 3, 'shareCount': 7},
    }, isFavorite: false);
    expect(item.copyWith(isFavorite: true).likeCount, 12);
    expect(item.commentCount, 3);
    expect(item.shareCount, 7);
    expect(RecipeItem.fromRecipeJson(json, isFavorite: false).shareCount, 0);
    expect(
      () => RecipeItem.fromRecipeJson({
        ...json,
        'engagement': {'likeCount': -1},
      }, isFavorite: false),
      throwsFormatException,
    );
  });
  for (final width in [320.0, 844.0]) {
    testWidgets('post counters retain actions and fit large text at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var saved = 0, comments = 0, shares = 0, opened = 0;
      final recipe = homeFixture().recipes.first.copyWith(
        likeCount: 1234,
        commentCount: 12,
        shareCount: 1000000,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(2),
              ),
              child: SingleChildScrollView(
                child: HomeRecipePost(
                  recipe: recipe,
                  onOpen: () => opened++,
                  onFavorite: () => saved++,
                  onReview: () => comments++,
                  onShare: () => shares++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Lưu công thức',
        'Đánh giá cộng đồng',
        'Chia sẻ công thức',
      ]) {
        final target = find.byTooltip(label);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        AppTapHandler.resetLock();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      expect([saved, comments, shares, opened], [1, 1, 1, 0]);
      expect(find.byType(PostAction), findsNWidgets(3));
      expect(find.text('1.2k'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
