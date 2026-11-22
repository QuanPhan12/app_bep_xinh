import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/home/widgets/home_feed_view.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_remix.dart';

import '../../support/mock_services.dart';

RecipeRemix origin({String authorName = 'Bếp gốc'}) => RecipeRemix(
  recipeId: 'r_original',
  title: 'Công thức gốc',
  authorId: 'original_author',
  authorName: authorName,
  sourceHash: 'a'.padRight(64, 'a'),
  changes: 'Giảm lượng dầu khi nấu.',
);
RecipeItem post({RecipeRemix? remix}) => RecipeItem(
  id: 'r_variant',
  title: 'Phiên bản ít dầu',
  image: 'assets/images/logo.png',
  rating: 0,
  cookTimeMinutes: 20,
  tag: '',
  authorId: 'new_author',
  authorName: 'Bếp mới',
  remix: remix,
);

void main() {
  test(
    'canonical feed parsing and favorite changes retain original attribution',
    () {
      final raw = Map<String, dynamic>.from(
        (fixtureJson('recipe_details')['recipes'] as List).first as Map,
      );
      raw['remix'] = origin().toJson();
      final parsed = RecipeItem.fromRecipeJson(raw, isFavorite: false);
      expect(parsed.remix, origin());
      expect(parsed.copyWith(isFavorite: true).remix, origin());
      expect(parsed.copyWith(isFavorite: true).authorId, parsed.authorId);
      expect(post(remix: origin()), isNot(post()));
    },
  );
  testWidgets(
    'source link credits original account and does not open the repost',
    (tester) async {
      var originalOpened = 0, postOpened = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeRecipePost(
                recipe: post(remix: origin()),
                onOpen: () => postOpened++,
                onSource: () => originalOpened++,
                onFavorite: null,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(PhosphorIconsRegular.linkSimple), findsOneWidget);
      expect(find.text('Biến tấu từ Bếp gốc'), findsOneWidget);
      expect(find.text('Bếp mới'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('post_remix_source_r_variant')),
      );
      await tester.pumpAndSettle();
      expect(originalOpened, 1);
      expect(postOpened, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ordinary post has no source row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeRecipePost(
              recipe: post(),
              onOpen: () {},
              onFavorite: null,
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(PhosphorIconsRegular.linkSimple), findsNothing);
    expect(
      find.byKey(const ValueKey('post_remix_source_r_variant')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 800.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'long source name fits width $width dark=$dark at large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HomeRecipePost(
                    recipe: post(
                      remix: origin(
                        authorName: 'Góc bếp gia đình với tên tài khoản dài để kiểm tra hiển thị',
                      ),
                    ),
                    onOpen: () {},
                    onSource: () {},
                    onFavorite: null,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('post_remix_source_r_variant')),
                )
                .height,
            greaterThanOrEqualTo(44),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
