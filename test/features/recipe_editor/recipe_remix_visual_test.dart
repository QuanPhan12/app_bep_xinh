import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_remix_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_remix_gate.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';
import 'package:app_bep_xinh/features/recipe_editor/cubits/recipe_editor/recipe_editor_cubit.dart';

import '../../support/auth_fake.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/recipe_editor_fakes.dart';

void main() {
  testWidgets('capture remix UI', (tester) async {
    configureAuthenticatedTaps();
    for (final family in ['BeVietnamPro', 'Be Vietnam Pro']) {
      final loader = FontLoader(family);
      for (final weight in [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
      ]) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf')
                  .readAsBytesSync(),
            ),
          ),
        );
      }
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final pair in [
      ('PhosphorRegular', 'Phosphor.ttf'),
      ('PhosphorBold', 'Phosphor-Bold.ttf'),
      ('PhosphorFill', 'Phosphor-Fill.ttf'),
    ]) {
      await (FontLoader('packages/phosphoricons_flutter/${pair.$1}')..addFont(
            rootBundle.load(
              'packages/phosphoricons_flutter/lib/fonts/${pair.$2}',
            ),
          ))
          .load();
    }
    Future<void> capture(String folder, String phase) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final element in find.byType(Image).evaluate()) {
        final provider = (element.widget as Image).image;
        if (provider is AssetImage || provider is ResizeImage) {
          await tester.runAsync(
            () => precacheImage(provider, element, onError: (_, _) {}),
          );
        }
      }
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('remix_capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui_ux/recipe_remix/$folder/$phase.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final width in [390.0, 800.0]) {
      for (final dark in [false, true]) {
        tester.view.physicalSize = Size(width, width == 390 ? 844 : 1100);
        tester.view.devicePixelRatio = 1;
        final editor = StubRecipeEditorService();
        final original = detailFixture();
        final details = StubRecipeDetailService()
          ..onFetch = (_) async => RecipeDetailData(
            recipe: RecipeDetail(
              id: 'r_source',
              author: original.author,
              content: original.content,
              contentHash: List.filled(64, 'a').join(),
            ),
            isFavorite: false,
            availableIngredientIds: {},
          );
        final service = RecipeRemixService(details: details, editor: editor);
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RecipeEditorService>.value(value: editor),
              RepositoryProvider<RecipeCoverPicker>.value(
                value: StubRecipeCoverPicker(),
              ),
            ],
            child: RepaintBoundary(
              key: const ValueKey('remix_capture'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                builder: AppTheme.builder,
                home: RecipeRemixGate(
                  service: service,
                  recipeId: 'r_source',
                  editorBuilder: (seed, previous) => RecipeEditorScreen(
                    seedDraft: seed,
                    expectedDraft: previous,
                  ),
                ),
              ),
            ),
          ),
        );
        final folder = '${width.toInt()}_${dark ? 'dark' : 'light'}';
        await capture(folder, 'gate');
        AppTapHandler.resetLock();
        await tester.tap(find.text('Bắt đầu chỉnh sửa'));
        await tester.pumpAndSettle();
        await capture(folder, 'editor');
        final cubit = tester
            .element(find.byKey(const ValueKey('recipe_remix_changes')))
            .read<RecipeEditorCubit>();
        cubit.changeRemixChanges(
          'Giảm lượng dầu, thêm nấm và điều chỉnh phần nước sốt cho gia đình.',
        );
        cubit.changeDescription(
          'Phiên bản giảm dầu và thêm nấm của gia đình mình.',
        );
        for (var step = 0; step < 3; step++) {
          cubit.nextStep();
          await tester.pumpAndSettle();
        }
        expect(cubit.state.step, RecipeEditorStep.review);
        await capture(folder, 'preview');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: !const bool.fromEnvironment('UI_CAPTURE_REMIX'));
}
