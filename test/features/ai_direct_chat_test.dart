import 'dart:async';
import 'dart:convert';

import 'package:app_bep_xinh/features/messages/models/chat_history_page.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_bep_xinh/features/ai_chat/services/direct_ai_chat_repository.dart';
import 'package:app_bep_xinh/features/ai_chat/services/direct_ai_store.dart';
import 'package:app_bep_xinh/features/ai_chat/models/ai_message.dart';

import '../support/auth_fake.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Store implements DirectAiStore {
  Map<String, dynamic> settings = {
    'provider': 'gemini',
    'endpoint': 'https://generativelanguage.googleapis.com',
    'model': 'gemini-test-flash',
    'enabled': true,
    'apiKey': 'test-only-key-12345',
    'dailyLimit': 40,
  };
  List<AiMessage>? cached;
  bool completed = false, failed = false, visible = true;
  @override
  Future<Map<String, dynamic>> config() async => settings;
  @override
  Future<ChatHistoryPage<AiMessage>> history(String uid) async =>
      const ChatHistoryPage([]);
  @override
  Future<List<AiMessage>> recentHistory(String uid) async => [];
  @override
  Future<List<Map<String, dynamic>>> recipes() async => [
    {
      'id': 'r_test',
      'content': {
        'title': 'Trứng chiên',
        'ingredients': [],
        'preparationMinutes': 5,
        'cookingMinutes': 5,
        'cover': {
          'id': 'cover',
          'name': 'test.png',
          'url':
              'https://res.cloudinary.com/ddqouziau/image/upload/v1/test.png',
          'publicId': 'test',
        },
      },
    },
  ];
  @override
  Future<bool> isApproved(String id) async => visible;
  @override
  Future<AiReservation> reserve(
    String uid,
    String id,
    String message,
    int limit,
  ) async => AiReservation(1, cached);
  @override
  Future<void> complete(
    String uid,
    String id,
    int lease,
    List<AiMessage> pair,
  ) async {
    completed = true;
  }

  @override
  Future<void> fail(String uid, String id, int lease) async {
    failed = true;
  }
}

void main() {
  const id = '0123456789abcdef0123456789abcdef';
  late _Auth auth;
  late _User user;
  late StubAuthService session;
  late _Store store;
  setUp(() {
    auth = _Auth();
    user = _User();
    session = StubAuthService()..id = 'alice';
    store = _Store();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('alice');
  });
  tearDown(() => session.dispose());
  DirectAiChatRepository repository(
    Future<http.Response> Function(http.Request) send,
  ) => DirectAiChatRepository(
    client: MockClient(send),
    auth: auth,
    session: session,
    store: store,
  );
  http.Response answer() => http.Response(
    jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'text': jsonEncode({
                  'reply': 'Thử món này nhé.',
                  'recipeIds': ['r_test', 'invented'],
                }),
              },
            ],
          },
        },
      ],
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  test('Reads admin configuration and calls Gemini directly; only real approved cards survive', () async {
    final repo = repository((request) async {
      expect(request.url.host, 'generativelanguage.googleapis.com');
      expect(
        request.url.path,
        '/v1beta/models/gemini-test-flash:generateContent',
      );
      expect(request.headers['x-goog-api-key'], 'test-only-key-12345');
      expect(request.headers.containsKey('Authorization'), false);
      expect(request.body.contains('CANDIDATES'), true);
      return answer();
    });
    final pair = await repo.send('Tôi có trứng', id);
    expect(pair.length, 2);
    expect(pair.last.recipes.single.id, 'r_test');
    expect(store.completed, true);
  });
  test('Account switching while provider is running discards response and history writes', () async {
    final pending = Completer<http.Response>(), started = Completer<void>();
    final repo = repository((_) {
      started.complete();
      return pending.future;
    });
    final result = repo.send('Gợi ý món', id);
    await started.future;
    session.id = 'bob';
    pending.complete(answer());
    await expectLater(result, throwsA(isA<AiChatFailure>()));
    expect(store.completed, false);
    expect(store.failed, false);
  });
  test('Provider quota failures keep raw key/content out of errors and record failure', () async {
    final repo = repository(
      (_) async =>
          http.Response('test-only-key-12345 raw private provider error', 429),
    );
    await expectLater(
      repo.send('Gợi ý món', id),
      throwsA(
        isA<AiChatFailure>().having(
          (e) => e.message,
          'safe error',
          allOf(contains('429'), isNot(contains('test-only-key'))),
        ),
      ),
    );
    expect(store.failed, true);
  });
  test('Saved retry result avoids another generation call; disabled config never calls API', () async {
    store.cached = [
      const AiMessage(id: 'a', role: 'assistant', text: 'Đã trả lời'),
    ];
    final repo = repository(
      (_) async => throw StateError('must not call provider'),
    );
    expect((await repo.send('Gợi ý món', id)).single.text, 'Đã trả lời');
    store.settings['enabled'] = false;
    await expectLater(repo.send('Món khác', id), throwsA(isA<AiChatFailure>()));
  });
  test('Compatible API uses configured endpoint/model and direct bearer authentication', () async {
    store.settings = {
      ...store.settings,
      'provider': 'openai-compatible',
      'endpoint': 'https://example.test/v1',
      'model': 'test-model',
    };
    final repo = repository((request) async {
      expect(
        request.url.toString(),
        'https://example.test/v1/chat/completions',
      );
      expect(request.headers['Authorization'], 'Bearer test-only-key-12345');
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({'reply': 'Chào bạn', 'recipeIds': []}),
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    expect((await repo.send('Chào', id)).last.text, 'Chào bạn');
  });
}
