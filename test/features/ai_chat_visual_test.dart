import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/ai_chat/models/ai_message.dart';
import 'package:app_bep_xinh/features/ai_chat/services/ai_chat_repository.dart';
import 'package:app_bep_xinh/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:app_bep_xinh/features/ai_chat/widgets/ai_chat_session_scope.dart';
import 'package:app_bep_xinh/features/messages/models/chat_recipe.dart';
import 'package:app_bep_xinh/features/messages/models/chat_history_page.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';

class _VisualAi implements AiChatRepository {
  final bool welcome;
  _VisualAi(this.welcome);
  @override
  Future<ChatHistoryPage<AiMessage>> history() async => ChatHistoryPage(
    welcome
        ? const []
        : const [
            AiMessage(
              id: 'user',
              role: 'user',
              text: 'Tôi có đậu phụ và cà chua, nấu món gì?',
            ),
            AiMessage(
              id: 'ai',
              role: 'assistant',
              text: 'Bạn có thể làm đậu sốt cà chua: món dễ nấu, hợp ăn cùng cơm nóng. Mở công thức bên dưới để xem nguyên liệu và các bước nhé.',
              recipes: [
                ChatRecipe(
                  id: 'r_ai_visual',
                  title: 'Đậu sốt cà chua',
                  cover: RecipeImage.asset(
                    id: 'cover',
                    assetPath: 'assets/images/fridge_tofu_tomato.webp',
                  ),
                ),
              ],
            ),
          ],
  );
  @override
  Future<List<AiMessage>> send(String message, String requestId) async => [];
}

void main() {
  testWidgets('capture AI cooking assistant', (tester) async {
    for (final family in ['BeVietnamPro', 'Be Vietnam Pro']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
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
    ]) {
      await (FontLoader('packages/phosphoricons_flutter/${pair.$1}')..addFont(
            rootBundle.load(
              'packages/phosphoricons_flutter/lib/fonts/${pair.$2}',
            ),
          ))
          .load();
    }
    for (final width in [390.0, 800.0]) {
      for (final dark in [false, true]) {
        for (final welcome in [false, true]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            RepositoryProvider<AiChatRepository>.value(
              value: _VisualAi(welcome),
              child: AiChatSessionScope(
                child: MaterialApp(
                  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  home: const RepaintBoundary(
                    key: ValueKey('ai_capture'),
                    child: AiChatScreen(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final context = tester.element(find.byType(AiChatScreen));
            for (final image in tester.widgetList<Image>(find.byType(Image))) {
              await precacheImage(image.image, context);
            }
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('ai_capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/ui_ux/ai_chat/${width.toInt()}_${dark ? 'dark' : 'light'}_${welcome ? 'welcome' : 'reply'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: !const bool.fromEnvironment('UI_CAPTURE_AI'));
}
