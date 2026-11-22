import 'dart:async';

import 'package:app_bep_xinh/features/ai_chat/cubits/ai_chat_cubit.dart';
import 'package:app_bep_xinh/features/ai_chat/models/ai_message.dart';
import 'package:app_bep_xinh/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:app_bep_xinh/features/ai_chat/services/ai_chat_repository.dart';
import 'package:app_bep_xinh/features/ai_chat/widgets/ai_chat_floating_layer.dart';
import 'package:app_bep_xinh/features/ai_chat/widgets/ai_chat_session_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/test_text_styles.dart';

class _Repository implements AiChatRepository {
  int loads = 0;
  final response = Completer<List<AiMessage>>();
  @override
  Future<List<AiMessage>> history() async {
    loads++;
    return [];
  }

  @override
  Future<List<AiMessage>> send(String message, String requestId) =>
      response.future;
}

void main() {
  setUpAll(configureTestTextStyles);
  testWidgets(
    'AI session retains draft and pending response across route exits, resets on account change',
    (tester) async {
      final repository = _Repository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/messages/ai',
            builder: (_, _) => const AiChatScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      Widget app(String uid) => RepositoryProvider<AiChatRepository>.value(
        value: repository,
        child: AiChatSessionScope(
          key: ValueKey(uid),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpWidget(app('alice'));
      router.push('/messages/ai');
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.byType(AiChatScreen))
          .read<AiChatCubit>();
      await tester.enterText(find.byType(TextField), 'Nấu món gì?');
      router.pop();
      await tester.pumpAndSettle();
      expect(cubit.isClosed, false);
      router.push('/messages/ai');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Nấu món gì?',
      );
      final pending = cubit.send();
      await tester.pump();
      router.pop();
      await tester.pumpAndSettle();
      expect(cubit.state.sending, true);
      repository.response.complete([
        const AiMessage(id: 'answer', role: 'assistant', text: 'Canh rau nhé'),
      ]);
      await pending;
      router.push('/messages/ai');
      await tester.pumpAndSettle();
      expect(find.text('Canh rau nhé'), findsOneWidget);
      expect(cubit.state.draft, isEmpty);
      expect(repository.loads, 1);
      await tester.pumpWidget(app('bob'));
      await tester.pumpAndSettle();
      expect(cubit.isClosed, true);
      expect(find.text('Canh rau nhé'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Floating AI drags inside body, survives resizing and taps open chat',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: AiChatFloatingLayer(child: SizedBox.expand()),
              bottomNavigationBar: SizedBox(
                key: ValueKey('bottom'),
                height: 80,
              ),
            ),
          ),
          GoRoute(
            path: '/messages/ai',
            builder: (_, _) => const Scaffold(body: Text('AI opened')),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 840);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final handle = find.byKey(const ValueKey('ai_floating_drag_handle'));
      final before = tester.getRect(handle);
      expect(
        before.bottom,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('bottom'))).dy),
      );
      await tester.drag(handle, const Offset(-150, -200));
      await tester.pumpAndSettle();
      expect(tester.getRect(handle).left, lessThan(before.left));
      expect(find.text('AI opened'), findsNothing);
      await tester.drag(handle, const Offset(-900, -900));
      await tester.pumpAndSettle();
      expect(tester.getRect(handle).left, greaterThanOrEqualTo(12));
      expect(tester.getRect(handle).top, greaterThanOrEqualTo(12));
      tester.view.physicalSize = const Size(800, 390);
      await tester.pumpAndSettle();
      await tester.drag(handle, const Offset(1200, 1200));
      await tester.pumpAndSettle();
      expect(tester.getRect(handle).right, lessThanOrEqualTo(788));
      expect(tester.getRect(handle).bottom, lessThan(310));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('ai_floating_open')));
      await tester.pumpAndSettle();
      expect(find.text('AI opened'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
