import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/ai_chat/cubits/ai_chat_cubit.dart';
import 'package:app_bep_xinh/features/ai_chat/models/ai_message.dart';
import 'package:app_bep_xinh/features/ai_chat/services/ai_chat_repository.dart';
import 'package:app_bep_xinh/features/ai_chat/services/http_ai_chat_repository.dart';
import 'package:app_bep_xinh/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:app_bep_xinh/features/ai_chat/widgets/ai_chat_session_scope.dart';
import 'package:app_bep_xinh/features/messages/models/chat_recipe.dart';
import 'package:app_bep_xinh/features/messages/models/chat_history_page.dart';
import 'package:app_bep_xinh/features/messages/widgets/chat_history_list.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';

import '../support/auth_fake.dart';
import '../support/test_text_styles.dart';

class AiFake implements AiChatRepository {
  Future<List<AiMessage>> Function()? onHistory;
  LoadOlderMessages<AiMessage>? onOlder;
  Future<List<AiMessage>> Function(String, String)? onSend;
  int calls = 0;
  @override
  Future<ChatHistoryPage<AiMessage>> history() async =>
      ChatHistoryPage(await onHistory?.call() ?? [], loadOlder: onOlder);
  @override
  Future<List<AiMessage>> send(String message, String requestId) async {
    calls++;
    return onSend != null
        ? await onSend!(message, requestId)
        : [
            AiMessage(id: '${requestId}_u', role: 'user', text: message),
            AiMessage(
              id: '${requestId}_a',
              role: 'assistant',
              text: 'Bạn có thể thử món trứng chiên.',
              recipes: [recipe],
            ),
          ];
  }
}

const recipe = ChatRecipe(
  id: 'r_ai',
  title: 'Trứng chiên',
  cover: RecipeImage.asset(id: 'cover', assetPath: 'assets/images/logo.png'),
);

class MockAiAuth extends Mock implements FirebaseAuth {}

class MockAiUser extends Mock implements User {}

void main() {
  test('Local debug web uses the real-project AI proxy; release and overrides stay explicit', () {
    const local =
        'http://127.0.0.1:5001/bepxinh-b0be7/asia-southeast1/bepXinhAi';
    const production =
        'https://asia-southeast1-bepxinh-b0be7.cloudfunctions.net/bepXinhAi';
    for (final host in ['localhost', '127.0.0.1', '::1']) {
      expect(resolveAiApiBaseUrl(debugWeb: true, host: host), local);
      expect(resolveAiApiBaseUrl(debugWeb: false, host: host), production);
    }
    expect(
      resolveAiApiBaseUrl(debugWeb: true, host: 'bepxinh-b0be7.web.app'),
      production,
    );
    expect(
      resolveAiApiBaseUrl(
        debugWeb: true,
        host: 'localhost',
        configured:
            'http://127.0.0.1:5001/demo-bepxinh/asia-southeast1/bepXinhAi',
      ),
      contains('/demo-bepxinh/'),
    );
  });
  setUpAll(configureTestTextStyles);
  setUp(configureAuthenticatedTaps);
  test('Failed send preserves draft and requestId; edit changes ID; success clears draft', () async {
    final fake = AiFake();
    final edit = AiChatCubit(fake);
    addTearDown(edit.close);
    await edit.load();
    final ids = <String>[];
    fake.onSend = (m, id) async {
      ids.add(id);
      throw const AiChatFailure('offline');
    };
    edit.change('Tôi có trứng');
    await edit.send();
    await edit.send();
    expect(edit.state.draft, 'Tôi có trứng');
    expect(ids[0], ids[1]);
    edit.change('Món khác');
    await edit.send();
    expect(ids[2], isNot(ids[1]));
    fake.onSend = null;
    await edit.send();
    expect(edit.state.draft, isEmpty);
    expect(edit.state.messages.length, 2);
  });
  test(
    'Sending blocks duplicates and late completion after close is ignored',
    () async {
      final fake = AiFake(), pending = Completer<List<AiMessage>>();
      final edit = AiChatCubit(fake);
      await edit.load();
      edit.change('Món nào?');
      fake.onSend = (_, _) => pending.future;
      final sending = edit.send();
      await edit.send();
      edit.change('ignored');
      expect(fake.calls, 1);
      expect(edit.state.draft, 'Món nào?');
      await edit.close();
      pending.complete([]);
      await sending;
    },
  );
  test('Failed history blocks sends and can be retried', () async {
    final fake = AiFake();
    fake.onHistory = () async => throw const AiChatFailure('disabled');
    final cubit = AiChatCubit(fake);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.change('Hi');
    await cubit.send();
    expect(fake.calls, 0);
    fake.onHistory = null;
    await cubit.load();
    expect(cubit.state.loadFailed, false);
  });
  test(
    'HTTP repository authenticates and rejects a response after account switch',
    () async {
      final auth = MockAiAuth(),
          user = MockAiUser(),
          session = StubAuthService()..id = 'alice';
      addTearDown(session.dispose);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('alice');
      when(() => user.getIdToken()).thenAnswer((_) async => 'test-token');
      final pending = Completer<http.Response>();
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        return pending.future;
      });
      addTearDown(client.close);
      final repository = HttpAiChatRepository(
        client: client,
        auth: auth,
        session: session,
        baseUrl: 'https://example.test',
      );
      final request = repository.history();
      await Future<void>.delayed(Duration.zero);
      session.id = 'bob';
      pending.complete(http.Response(jsonEncode({'messages': []}), 200));
      await expectLater(request, throwsA(isA<AiChatFailure>()));
    },
  );
  testWidgets('AI loads older messages only after scrolling toward the top', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 450);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    List<AiMessage> messages(int start, int length) => List.generate(
      length,
      (i) => AiMessage(
        id: '${start + i}',
        role: 'user',
        text: 'Tin nhắn số ${start + i}',
      ),
    );
    var olderCalls = 0;
    final pending = Completer<ChatHistoryPage<AiMessage>>();
    final repository = AiFake();
    repository.onHistory = () async => messages(7, 6);
    repository.onOlder = () {
      olderCalls++;
      return pending.future;
    };
    final cubit = AiChatCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.messages.length, 6);
    expect(find.text('Tin nhắn số 12'), findsOneWidget);
    expect(olderCalls, 0);
    final list = find.byType(ChatHistoryList);
    await tester.drag(list, const Offset(0, 300));
    await tester.pump();
    expect(olderCalls, 1);
    expect(cubit.state.loadingOlder, true);
    final scroll = tester.widget<ChatHistoryList>(list).controller!;
    for (
      var frame = 0;
      frame < 20 && scroll.position.isScrollingNotifier.value;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final position = scroll.offset;
    pending.complete(ChatHistoryPage(messages(1, 6)));
    await tester.pumpAndSettle();
    expect(
      cubit.state.messages.map((m) => m.id),
      List.generate(12, (i) => '${i + 1}'),
    );
    expect(scroll.offset, closeTo(position, 2));
    expect(cubit.state.hasOlder, false);
  });
  testWidgets(
    'AI recipe card navigates, and mobile/tablet light/dark fit large text and keyboard',
    (tester) async {
      final fake = AiFake();
      fake.onHistory = () async => [
        const AiMessage(
          id: 'a',
          role: 'assistant',
          text: 'Món này dễ làm, hợp bữa tối.',
          recipes: [recipe],
        ),
      ];
      final router = GoRouter(
        initialLocation: '/messages/ai',
        routes: [
          GoRoute(
            path: '/messages/ai',
            builder: (_, _) => const AiChatScreen(),
          ),
          GoRoute(
            path: '/recipe/:id',
            builder: (_, state) =>
                Scaffold(body: Text('recipe ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      for (final width in [320.0, 800.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        for (final dark in [false, true]) {
          await tester.pumpWidget(
            RepositoryProvider<AiChatRepository>.value(
              value: fake,
              child: AiChatSessionScope(
                child: MaterialApp.router(
                  routerConfig: router,
                  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.5),
                      viewInsets: const EdgeInsets.only(bottom: 280),
                    ),
                    child: child!,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final draft in [
            'Tôi có trứng',
            'Tôi có trứng\nvà cà chua\nnấu gì?',
          ]) {
            await tester.enterText(find.byType(TextField), draft);
            await tester.pumpAndSettle();
            expect(
              (tester.getCenter(find.byType(TextField)).dy -
                      tester.getCenter(find.byTooltip('Gửi cho AI')).dy)
                  .abs(),
              lessThan(1),
              reason: 'Nút gửi phải căn giữa ô nhập, không căn theo dòng đếm.',
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.tap(find.text('Trứng chiên'));
      await tester.pumpAndSettle();
      expect(find.text('recipe r_ai'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
