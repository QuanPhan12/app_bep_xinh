import 'dart:async';

import 'package:app_bep_xinh/features/recipe_editor/cubits/recipe_editor/recipe_editor_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_draft_codec.dart';
import 'package:app_bep_xinh/features/recipe_editor/widgets/recipe_cover_field.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/home/widgets/home_feed_view.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_image_gallery.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_content_overview.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/recipe_editor_fakes.dart';
import '../../support/mock_services.dart';
import '../../support/test_text_styles.dart';

class _Picker extends StubRecipeCoverPicker implements RecipePhotosPicker {
  List<RecipeCover> photos = [];
  List<RecipeCover> recovered = [];
  Completer<List<RecipeCover>>? pending;
  @override
  Future<List<RecipeCover>> pickPhotos(int limit) async =>
      pending == null ? photos : pending!.future;
  @override
  Future<List<RecipeCover>> recoverLostPhotos() async => recovered;
}

void main() {
  setUpAll(configureTestTextStyles);
  test(
    'late multi-selection result is discarded after editor closes',
    () async {
      final pending = Completer<List<RecipeCover>>();
      final picker = _Picker()..pending = pending;
      final cubit = RecipeEditorCubit(
        service: StubRecipeEditorService(),
        coverPicker: picker,
      );
      await cubit.loadDraft();
      final task = cubit.addPhotos();
      expect(cubit.state.isBusy, isTrue);
      await cubit.close();
      pending.complete([recipeCoverFixture()]);
      await task;
      expect(cubit.state.draft.cover, isNull);
    },
  );
  test('multiple selection, cover promotion, deletion and cancellation preserve order', () async {
    final picker = _Picker()
      ..photos = [
        recipeCoverFixture(id: 'a'),
        recipeCoverFixture(id: 'b'),
        recipeCoverFixture(id: 'c'),
      ];
    final cubit = RecipeEditorCubit(
      service: StubRecipeEditorService(),
      coverPicker: picker,
    );
    addTearDown(cubit.close);
    await cubit.loadDraft();
    await cubit.addPhotos();
    expect(cubit.state.draft.cover!.id, 'a');
    expect(cubit.state.draft.photos.map((image) => image.id), ['b', 'c']);
    cubit.makeCover('c');
    expect(cubit.state.draft.cover!.id, 'c');
    expect(cubit.state.draft.photos.map((image) => image.id), ['a', 'b']);
    cubit.removeCover();
    expect(cubit.state.draft.cover!.id, 'a');
    cubit.removePhoto('b');
    final before = cubit.state.draft;
    picker.photos = [];
    await cubit.addPhotos();
    expect(cubit.state.draft, before);
    expect(cubit.state.hasUnsavedChanges, isTrue);
  });

  test('limit rejects the whole oversized selection and recovers multiple Android images', () async {
    final picker = _Picker()
      ..recovered = [recipeCoverFixture(id: 'a'), recipeCoverFixture(id: 'b')];
    final cubit = RecipeEditorCubit(
      service: StubRecipeEditorService(),
      coverPicker: picker,
    );
    addTearDown(cubit.close);
    await cubit.loadDraft();
    expect(cubit.state.draft.cover!.id, 'a');
    expect(cubit.state.draft.photos.single.id, 'b');
    final before = cubit.state.draft;
    picker.photos = List.generate(9, (i) => recipeCoverFixture(id: 'new_$i'));
    await cubit.addPhotos();
    expect(cubit.state.draft, before);
    expect(cubit.state.message, contains('10'));
  });

  test(
    'draft, remix content and feed retain photos; legacy content has no extras',
    () async {
      final catalog = await MockIngredientCatalogService(fixtureApi())
          .fetchCatalog();
      final draft = validRecipeDraft().copyWith(
        photos: [recipeCoverFixture(id: 'b')],
      );
      expect(
        RecipeDraftCodec.decode(RecipeDraftCodec.encode(draft), catalog),
        draft,
      );
      final content = RecipeContent.fromJson(
        draft.toRecipeContent().toJson(),
        catalog,
      );
      expect(RecipeDraft.fromContent(content).photos, draft.photos);
      expect(content.images.map((image) => image.id), ['cover', 'b']);
      final feed = RecipeItem.fromRecipeJson({
        'id': 'r_post',
        ...content.toJson(),
      }, isFavorite: false);
      expect(feed.copyWith(isFavorite: true).photos, draft.photos);
      final legacy = content.toJson()..remove('photos');
      expect(RecipeContent.fromJson(legacy, catalog).photos, isEmpty);
      expect(
        () => decodeRecipePhotos(List.filled(10, draft.cover!.toJson())),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'editor shows extra photos and cover controls without overflow at 320 px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final picker = _Picker()
        ..photos = [recipeCoverFixture(id: 'a'), recipeCoverFixture(id: 'b')];
      final cubit = RecipeEditorCubit(
        service: StubRecipeEditorService(),
        coverPicker: picker,
      );
      addTearDown(cubit.close);
      await cubit.loadDraft();
      await cubit.addPhotos();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const SingleChildScrollView(child: RecipeCoverField()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thêm ảnh (2/10)'), findsOneWidget);
      await tester.tap(find.text('Làm ảnh bìa'));
      await tester.pumpAndSettle();
      expect(cubit.state.draft.cover!.id, 'b');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'post uses dots and swiping while detail keeps its gallery controls',
    (tester) async {
      final draft = validRecipeDraft().copyWith(
        photos: [recipeCoverFixture(id: 'b')],
      );
      final content = draft.toRecipeContent();
      for (final child in [
        HomeRecipePost(
          recipe: RecipeItem(
            id: 'r_post',
            title: 'Món',
            image: 'assets/images/logo.png',
            photos: const [
              RecipeImage.asset(id: 'b', assetPath: 'assets/images/logo.png'),
            ],
            rating: 0,
            cookTimeMinutes: 20,
            tag: '',
          ),
          onOpen: () {},
          onFavorite: null,
        ),
        RecipeContentOverview(content: content),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        );
        await tester.pumpAndSettle();
        final isPost = child is HomeRecipePost;
        final secondDot = find.byKey(const ValueKey('recipe_photo_dot_1'));
        if (isPost) {
          expect(find.text('Ảnh 1/2'), findsNothing);
          expect(find.byTooltip('Ảnh tiếp theo'), findsNothing);
          expect(find.byTooltip('Ảnh trước'), findsNothing);
          expect(secondDot, findsOneWidget);
          expect(
            tester.getTopLeft(secondDot).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(find.byType(PageView)).dy),
          );
          await tester.drag(
            find.byType(RecipeImageGallery),
            const Offset(-500, 0),
          );
        } else {
          expect(find.text('Ảnh 1/2'), findsOneWidget);
          await tester.tap(find.byTooltip('Ảnh tiếp theo'));
        }
        await tester.pumpAndSettle();
        if (isPost) {
          expect(
            tester.widget<Semantics>(secondDot).properties.selected,
            isTrue,
          );
          final firstDot = find.byKey(const ValueKey('recipe_photo_dot_0'));
          await tester.ensureVisible(firstDot);
          await tester.pumpAndSettle();
          await tester.tap(firstDot);
        } else {
          expect(find.text('Ảnh 2/2'), findsOneWidget);
          await tester.drag(
            find.byType(RecipeImageGallery),
            const Offset(500, 0),
          );
        }
        await tester.pumpAndSettle();
        if (isPost) {
          expect(
            tester.widget<Semantics>(secondDot).properties.selected,
            isFalse,
          );
        } else {
          expect(find.text('Ảnh 1/2'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
}
