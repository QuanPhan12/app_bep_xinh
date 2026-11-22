import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/features/messages/models/chat_recipe.dart';
import 'package:app_bep_xinh/features/messages/services/message_repository.dart';
import 'package:app_bep_xinh/features/messages/services/chat_image_service.dart';
import 'package:app_bep_xinh/features/messages/screens/conversation_screen.dart';

import '../../support/auth_fake.dart';
import '../../support/communication_fakes.dart';
import '../../support/recipe_detail_fakes.dart';

void main() {
  testWidgets('capture chat recipe UI', (tester) async {
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
    Future<void> tap(Finder target) async {
      AppTapHandler.resetLock();
      await tester.tap(target);
      await tester.pumpAndSettle();
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
        find.byKey(const ValueKey('chat_recipe_capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui_ux/chat_recipe/$folder/$phase.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final width in [390.0, 800.0]) {
      for (final dark in [false, true]) {
        tester.view.physicalSize = Size(width, width == 390 ? 844 : 1100);
        tester.view.devicePixelRatio = 1;
        final repository = FakeMessageRepository(),
            images = FakeChatImageService();
        final fixture = detailFixture();
        // Ảnh asset chỉ dùng cho capture layout; repository thật yêu cầu snapshot ảnh remote đã duyệt.
        repository.recipeOptions = [
          ChatRecipe(
            id: 'r_chat_recipe',
            title: fixture.title,
            cover: fixture.cover!,
          ),
        ];
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<MessageRepository>.value(value: repository),
              RepositoryProvider<ChatImageService>.value(value: images),
            ],
            child: RepaintBoundary(
              key: const ValueKey('chat_recipe_capture'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                builder: AppTheme.builder,
                home: ConversationScreen(id: repository.thread.id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('message_draft')),
          'Cuối tuần mình thử nấu món này nhé!',
        );
        await tap(find.byTooltip('Đính kèm'));
        await tap(find.text('Chọn công thức'));
        final folder = '${width.toInt()}_${dark ? 'dark' : 'light'}';
        await capture(folder, 'picker');
        await tap(find.text(fixture.title));
        await capture(folder, 'preview');
        await tap(find.byTooltip('Gửi tin nhắn'));
        await capture(folder, 'sent');
        await tester.pumpWidget(const SizedBox.shrink());
        await repository.dispose();
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: !const bool.fromEnvironment('UI_CAPTURE_CHAT_RECIPE'));
}
