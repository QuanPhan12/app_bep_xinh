import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/features/recipe_detail/screens/recipe_detail_screen.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../support/auth_fake.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_remix_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_draft_codec.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/cubits/recipe_editor/recipe_editor_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_remix_gate.dart';
import 'package:app_bep_xinh/features/recipe_editor/validation/recipe_editor_validation.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/recipe_editor_fakes.dart';

RecipeDetail remixSource() => RecipeDetail(
  id: 'r_source',
  author: const RecipeAuthor(id: 'original_author', name: 'Bếp gốc'),
  content: validRecipeDraft()
      .copyWith(
        cover: const RecipeImage.remote(
          id: 'cover',
          name: 'food',
          url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/food.png',
          publicId: 'food',
        ),
      )
      .toRecipeContent(),
  contentHash: List.filled(64, 'a').join(),
);

void main() {
  late StubRecipeDetailService details;
  late StubRecipeEditorService editor;
  late RecipeRemixService service;
  setUp(() {
    configureAuthenticatedTaps();
    AppTapHandler.resetLock();
    details = StubRecipeDetailService()
      ..onFetch = (_) async => RecipeDetailData(
        recipe: remixSource(),
        isFavorite: false,
        availableIngredientIds: {},
      );
    editor = StubRecipeEditorService();
    service = RecipeRemixService(details: details, editor: editor);
  });
  test(
    'seed preserves cooking content, authorship source and independent draft',
    () async {
      final seed = await service.load('r_source');
      expect(seed.draft.title, remixSource().title);
      expect(
        seed.draft.ingredients,
        RecipeDraft.fromContent(remixSource().content).ingredients,
      );
      expect(seed.draft.remix!.authorId, 'original_author');
      expect(seed.draft.remix!.changes, '');
      expect(seed.replacesDraft, false);
      expect(editor.saved, isNull);
      expect(
        RecipeEditorValidation.validate(seed.draft),
        contains('remixChanges'),
      );
      final unchanged = seed.draft.copyWith(
        remix: seed.draft.remix!.withChanges('Giảm dầu khi chiên trứng.'),
      );
      expect(
        RecipeEditorValidation.validate(unchanged),
        contains('remixContent'),
      );
      final changed = unchanged.copyWith(
        description: 'Chiên bằng chảo chống dính, giảm dầu.',
      );
      expect(RecipeEditorValidation.validate(changed), isEmpty);
      final restored = RecipeDraftCodec.decode(
        RecipeDraftCodec.encode(changed),
        catalogFixture(),
      );
      expect(restored, changed);
      expect(restored.remixBaseline, seed.draft.remixBaseline);
      expect(remixSource().description, isNot(changed.description));
    },
  );
  test(
    'different saved draft is retained until user explicitly starts and saves',
    () async {
      editor.saved = validRecipeDraft().copyWith(title: 'Nháp đang viết');
      final previous = editor.saved;
      final seed = await service.load('r_source');
      expect(seed.replacesDraft, true);
      expect(seed.previous, previous);
      expect(editor.saved, previous);
      expect(editor.saveCalls, 0);
    },
  );
  test(
    'opening the same source resumes saved changes instead of overwriting them',
    () async {
      final seed = await service.load('r_source');
      editor.saved = seed.draft.copyWith(
        title: 'Bản ít dầu',
        remix: seed.draft.remix!.withChanges('Chiên ít dầu hơn bản gốc.'),
      );
      final resumed = await service.load('r_source');
      expect(resumed.draft, editor.saved);
      expect(resumed.replacesDraft, false);
    },
  );
  test(
    'invalid IDs and source without canonical metadata cannot be remixed',
    () async {
      await expectLater(service.load('fixture_recipe'), throwsException);
      details.onFetch = (_) async => detailDataFixture();
      await expectLater(service.load('r_source'), throwsException);
      expect(editor.saved, isNull);
    },
  );
  test('editor refuses seed if the draft changed after confirmation', () async {
    final seed = await service.load('r_source');
    editor.saved = validRecipeDraft().copyWith(title: 'Nháp từ phiên khác');
    final cubit = RecipeEditorCubit(
      service: editor,
      coverPicker: StubRecipeCoverPicker(),
      seedDraft: seed.draft,
      expectedDraft: seed.previous,
    );
    await cubit.loadDraft();
    expect(cubit.state.status, RecipeEditorStatus.loadFailure);
    expect(editor.saveCalls, 0);
    await cubit.close();
  });
  test('new remix starts dirty and keeps the saved draft baseline', () async {
    final seed = await service.load('r_source');
    final cubit = RecipeEditorCubit(
      service: editor,
      coverPicker: StubRecipeCoverPicker(),
      seedDraft: seed.draft,
      expectedDraft: seed.previous,
    );
    await cubit.loadDraft();
    expect(cubit.state.hasUnsavedChanges, true);
    expect(cubit.state.canLeave, false);
    cubit.changeRemixChanges('Giảm đường trong phần nước sốt.');
    expect(cubit.state.draft.remix!.changes, contains('Giảm đường'));
    await cubit.close();
  });
  testWidgets(
    'gate cancellation preserves draft, confirmed seed opens the shared editor',
    (tester) async {
      editor.saved = validRecipeDraft().copyWith(title: 'Nháp đang viết');
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RecipeEditorService>.value(value: editor),
            RepositoryProvider<RecipeCoverPicker>.value(
              value: StubRecipeCoverPicker(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: RecipeRemixGate(
              service: service,
              recipeId: 'r_source',
              editorBuilder: (seed, previous) =>
                  RecipeEditorScreen(seedDraft: seed, expectedDraft: previous),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giữ bản nháp'));
      await tester.pumpAndSettle();
      expect(editor.saved!.title, 'Nháp đang viết');
      expect(editor.saveCalls, 0);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Bắt đầu chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã điều chỉnh gì?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('recipe_remix_changes')),
        'Giảm lượng dầu và dùng chảo chống dính.',
      );
      await tester.pump();
      final cubit = tester
          .element(find.byKey(const ValueKey('recipe_remix_changes')))
          .read<RecipeEditorCubit>();
      expect(cubit.state.draft.remix!.changes, contains('chống dính'));
      expect(editor.saved!.title, 'Nháp đang viết');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('recipe menu opens remix route with its source ID', (
    tester,
  ) async {
    final favorites = StubRecipeFavoritesService();
    final router = GoRouter(
      initialLocation: '/recipe/r_source',
      routes: [
        GoRoute(
          path: '/recipe/:id',
          builder: (_, state) =>
              RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/recipes/new',
          builder: (_, state) => Scaffold(
            body: Text('remix_id:${state.uri.queryParameters['remix']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(favorites.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RecipeDetailService>.value(value: details),
          RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn công thức'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biến tấu công thức'));
    await tester.pumpAndSettle();
    expect(find.text('remix_id:r_source'), findsOneWidget);
    expect(AppTapHandler.isBusy, false);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 800.0]) {
    for (final dark in [false, true]) {
      testWidgets('remix gate fits width $width dark=$dark with large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
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
            home: RecipeRemixGate(
              service: service,
              recipeId: 'r_source',
              editorBuilder: (_, _) => const Text('editor'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Bắt đầu chỉnh sửa'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(AppContentScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
