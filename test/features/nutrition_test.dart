import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/ai_chat/models/ai_message.dart';
import 'package:app_bep_xinh/features/ai_chat/services/ai_model_client.dart';
import 'package:app_bep_xinh/features/ai_chat/services/direct_ai_chat_repository.dart';
import 'package:app_bep_xinh/features/ai_chat/services/direct_ai_store.dart';
import 'package:app_bep_xinh/features/nutrition/models/nutrition.dart';
import 'package:app_bep_xinh/features/nutrition/cubits/nutrition_cubit.dart';
import 'package:app_bep_xinh/features/nutrition/services/nutrition_repository.dart';
import 'package:app_bep_xinh/features/nutrition/services/nutrition_photo_picker.dart';
import 'package:app_bep_xinh/features/nutrition/screens/nutrition_screen.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';

import '../support/nutrition_fakes.dart';
import '../support/kitchen_fakes.dart';
import '../support/recipe_detail_fakes.dart';
import '../support/auth_fake.dart';
import '../support/test_text_styles.dart';

import 'package:app_bep_xinh/features/ingredients/services/ingredient_discovery_service.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Discoveries implements IngredientDiscoveryService {
  int calls = 0;
  final names = <String>[];
  @override
  Future<void> saveDiscovered(String requestId, Iterable<String> values) async {
    calls++;
    if (calls == 1) throw StateError('offline');
    names.addAll(values);
  }
}

class _ChatStore extends Fake implements DirectAiStore {
  @override
  Future<AiReservation> reserve(
    String uid,
    String id,
    String text,
    int limit,
  ) async => const AiReservation(1);
  @override
  Future<List<AiMessage>> recentHistory(String uid) async => [];
  @override
  Future<List<Map<String, dynamic>>> recipes() async => [];
  @override
  Future<void> complete(
    String uid,
    String id,
    int lease,
    List<AiMessage> pair,
  ) async {}
  @override
  Future<void> fail(String uid, String id, int lease) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestTextStyles);
  test(
    'nutrition catalog is bundled and loads through the production repository',
    () async {
      final session = StubAuthService(),
          journal = MemoryKitchenRepository<NutritionEntry>();
      final client = MockClient((_) async => http.Response('', 500));
      addTearDown(session.dispose);
      addTearDown(journal.dispose);
      addTearDown(client.close);
      final repo = DefaultNutritionRepository(
        model: AiModelClient(
          client: client,
          auth: _Auth(),
          session: session,
          loadConfig: () async => {},
        ),
        jobs: FakeNutritionJobs(),
        journal: journal,
      );
      expect((await repo.catalog()).foods.length, 7793);
      expect((await repo.catalog()).byIngredient['egg']!.id, '171287');
    },
  );
  testWidgets(
    'manual confirmed meal saves from the screen and title editing retains focus',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeNutritionRepository(), kitchen = kitchenFixture();
      addTearDown(repo.journal.dispose);
      addTearDown(() => disposeKitchen(kitchen));
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<NutritionRepository>.value(value: repo),
            RepositoryProvider<NutritionPhotoPicker>.value(
              value: FakeNutritionPhotos(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: KitchenScope(
              services: kitchen,
              child: const NutritionScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.text('Ước tính calo').first)
          .read<NutritionCubit>();
      expect(find.text('Thông tin bữa ăn'), findsNothing);
      expect(find.text('Tên bữa'), findsNothing);
      cubit.addFood(nutritionCatalogFixture().byIngredient['egg']!);
      cubit.line(0, grams: 100);
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      await tester.tap(find.text('Tính calo'));
      await tester.pumpAndSettle();
      expect(find.text('143 kcal'), findsOneWidget);
      await tester.tap(find.text('Lưu bữa ăn'));
      await tester.pumpAndSettle();
      final title = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Tên bữa',
      );
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      final editable = find.descendant(
        of: title,
        matching: find.byType(EditableText),
      );
      final focus = tester.widget<EditableText>(editable).focusNode;
      await tester.enterText(title, 'Bữa trưa của tôi');
      await tester.pumpAndSettle();
      expect(focus.hasFocus, true);
      expect(tester.widget<EditableText>(editable).focusNode, same(focus));
      await tester.tap(find.text('Đã ăn · Lưu nhật ký'));
      await tester.pumpAndSettle();
      expect((await repo.journal.fetch()).single.title, 'Bữa trưa của tôi');
      expect(find.text('Ước tính bữa khác'), findsOneWidget);
      await tester.tap(find.text('Nhật ký ăn'));
      await tester.pumpAndSettle();
      expect(find.text('Bữa trưa của tôi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  test(
    'USDA records calculate per 100g; unknown food cannot become zero calories',
    () {
      final catalog = nutritionCatalogFixture();
      expect(catalog.foods.length, 7793);
      final egg = catalog.byIngredient['egg']!;
      final totals = catalog.total([
        NutritionLine(
          id: 'egg',
          name: 'Trứng',
          foodId: egg.id,
          grams: 200,
          confirmed: true,
        ),
      ]);
      expect(totals.kcal, egg.kcal * 2);
      expect(totals.scaled(.5).protein, egg.protein);
      expect(
        catalog.byIngredient['cooked_rice']!.kcal,
        isNot(catalog.byIngredient['rice']!.kcal),
      );
      expect(
        () => catalog.total([
          const NutritionLine(
            id: 'unknown',
            name: 'Thiếu dữ liệu',
            grams: 100,
            confirmed: true,
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => catalog.total([
          NutritionLine(id: 'egg', name: 'Trứng', foodId: egg.id, grams: 100),
        ]),
        throwsFormatException,
      );
    },
  );
  test('draft confirms quantities, clearing grams invalidates totals; consumed portions save once', () async {
    final repo = FakeNutritionRepository(), kitchen = kitchenFixture();
    addTearDown(repo.journal.dispose);
    addTearDown(() => disposeKitchen(kitchen));
    final cubit = NutritionCubit(
      repository: repo,
      photos: FakeNutritionPhotos(),
      kitchen: kitchen,
    );
    addTearDown(cubit.close);
    await cubit.load();
    cubit.addFood(cubit.state.catalog!.byIngredient['egg']!);
    cubit.line(0, grams: 200);
    cubit.confirmAll();
    expect(cubit.state.ready, true);
    cubit.line(0, clearGrams: true);
    expect(cubit.state.ready, false);
    expect(await cubit.save(), false);
    cubit.line(0, grams: 200);
    cubit.confirmAll();
    cubit.metadata(servings: 4, consumed: 1);
    expect(await cubit.save(), true);
    expect(await cubit.save(), true);
    expect(await repo.journal.count(), 1);
    final saved = (await repo.journal.fetch()).single;
    expect(
      saved.totals.kcal,
      cubit.state.catalog!.byIngredient['egg']!.kcal * .5,
    );
    expect(
      NutritionEntry.fromJson(saved.id, saved.toJson()).consumedServings,
      1,
    );
    cubit.reset();
    expect(cubit.state.lines, isEmpty);
    expect(cubit.state.saved, false);
  });
  test('recipe seed preserves original servings and requires grams for units without mass', () async {
    final repo = FakeNutritionRepository(), kitchen = kitchenFixture();
    addTearDown(repo.journal.dispose);
    addTearDown(() => disposeKitchen(kitchen));
    final cubit = NutritionCubit(
      repository: repo,
      photos: FakeNutritionPhotos(),
      kitchen: kitchen,
    );
    addTearDown(cubit.close);
    await cubit.load(recipeId: detailFixture().id, servings: 4);
    expect(cubit.state.servings, 4);
    expect(cubit.state.lines, isNotEmpty);
    expect(cubit.state.ready, false);
    expect(cubit.state.lines.every((l) => !l.confirmed), true);
    expect(cubit.state.lines.every((l) => l.name.length <= 80), true);
  });
  for (final gemini in [true, false]) {
    test(
      'nutrition and chat use the same changing admin model, image wire format and no AI nutrient values ($gemini)',
      () async {
        final auth = _Auth(),
            user = _User(),
            session = StubAuthService()..id = 'alice';
        addTearDown(session.dispose);
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.uid).thenReturn('alice');
        var currentModel = 'shared-one', calls = 0;
        final catalog = nutritionCatalogFixture(),
            egg = catalog.byIngredient['egg']!;
        final client = MockClient((request) async {
          calls++;
          final body = jsonDecode(request.body) as Map;
          expect(
            request.url.path,
            gemini
                ? '/v1beta/models/$currentModel:generateContent'
                : '/v1/chat/completions',
          );
          final nutrition = gemini
              ? (body['systemInstruction']['parts'][0]['text'] as String)
                    .contains('REFERENCES:')
              : (body['messages'][0]['content'] as String).contains(
                  'REFERENCES:',
                );
          if (nutrition) {
            if (gemini) {
              expect(
                body['contents'].last['parts'].last['inline_data']['mime_type'],
                'image/png',
              );
            } else {
              expect(body['model'], currentModel);
              expect(
                body['messages'].last['content'][1]['image_url']['url'],
                startsWith('data:image/png;base64,'),
              );
            }
          }
          final answer = nutrition
              ? {
                  'items': [
                    {
                      'id': 'image',
                      'name': 'Trứng',
                      'foodId': egg.id,
                      'grams': 100,
                      'kcal': 999999,
                    },
                  ],
                }
              : {'reply': 'Xin chào', 'recipeIds': []};
          return http.Response(
            jsonEncode(
              gemini
                  ? {
                      'candidates': [
                        {
                          'content': {
                            'parts': [
                              {'text': jsonEncode(answer)},
                            ],
                          },
                        },
                      ],
                    }
                  : {
                      'choices': [
                        {
                          'message': {'content': jsonEncode(answer)},
                        },
                      ],
                    },
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        addTearDown(client.close);
        final model = AiModelClient(
          client: client,
          auth: auth,
          session: session,
          loadConfig: () async => {
            'enabled': true,
            'provider': gemini ? 'gemini' : 'compatible',
            'apiKey': 'test-only-key-12345',
            'model': currentModel,
            'endpoint': gemini
                ? 'https://generativelanguage.googleapis.com'
                : 'https://example.test/v1',
            'dailyLimit': 40,
          },
        );
        final jobs = FakeNutritionJobs(),
            journal = MemoryKitchenRepository<NutritionEntry>();
        addTearDown(journal.dispose);
        final repo = DefaultNutritionRepository(
          model: model,
          jobs: jobs,
          journal: journal,
        );
        final lines = await repo.recognize(
          id: '0123456789abcdef0123456789abcdef',
          text: 'Trứng',
          catalog: catalog,
          image: Uint8List.fromList([1, 2, 3]),
        );
        expect(lines.single.confirmed, false);
        expect(
          catalog.total([lines.single.change(confirmed: true)]).kcal,
          egg.kcal,
        );
        await repo.recognize(
          id: '0123456789abcdef0123456789abcdef',
          text: 'Trứng',
          catalog: catalog,
          image: Uint8List.fromList([1, 2, 3]),
        );
        expect(calls, 1);
        currentModel = 'shared-two';
        final chat = DirectAiChatRepository(
          client: client,
          auth: auth,
          session: session,
          store: _ChatStore(),
          modelClient: model,
        );
        expect(
          (await chat.send(
            'Xin chào',
            'abcdef0123456789abcdef0123456789',
          )).last.text,
          'Xin chào',
        );
        expect(calls, 2);
      },
    );
  }
  test('discovery retry uses cached AI result; hallucinated IDs and account switches remain blocked', () async {
    final auth = _Auth(),
        user = _User(),
        session = StubAuthService()..id = 'alice';
    addTearDown(session.dispose);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('alice');
    var switchAccount = false;
    var providerCalls = 0;
    final client = MockClient((_) async {
      providerCalls++;
      if (switchAccount) session.id = 'bob';
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'items': [
                        {'name': 'Món lạ', 'foodId': 'invented', 'grams': 100},
                      ],
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
    });
    addTearDown(client.close);
    final model = AiModelClient(
      client: client,
      auth: auth,
      session: session,
      loadConfig: () async => {
        'enabled': true,
        'provider': 'gemini',
        'apiKey': 'test-only-key-12345',
        'model': 'shared',
        'endpoint': 'https://generativelanguage.googleapis.com',
      },
    );
    final journal = MemoryKitchenRepository<NutritionEntry>();
    addTearDown(journal.dispose);
    final discoveries = _Discoveries(), jobs = FakeNutritionJobs();
    final repo = DefaultNutritionRepository(
      model: model,
      jobs: jobs,
      journal: journal,
      discoveries: discoveries,
    );
    await expectLater(
      repo.recognize(
        id: '0123456789abcdef0123456789abcdef',
        text: 'Món lạ',
        catalog: nutritionCatalogFixture(),
      ),
      throwsA(isA<AiChatFailure>()),
    );
    expect(
      (await repo.recognize(
        id: '0123456789abcdef0123456789abcdef',
        text: 'Món lạ',
        catalog: nutritionCatalogFixture(),
      )).single.foodId,
      isNull,
    );
    expect(providerCalls, 1);
    expect(jobs.completed, 1);
    expect(jobs.failed, 0);
    expect(discoveries.names, ['Món lạ']);
    switchAccount = true;
    final fresh = DefaultNutritionRepository(
      model: model,
      jobs: FakeNutritionJobs(),
      journal: journal,
    );
    await expectLater(
      fresh.recognize(
        id: 'abcdef0123456789abcdef0123456789',
        text: 'Món lạ',
        catalog: nutritionCatalogFixture(),
      ),
      throwsA(isA<AiChatFailure>()),
    );
    expect(await journal.count(), 0);
  });
  for (final dark in [false, true]) {
    for (final size in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      testWidgets(
        'nutrition fits $size dark=$dark with large text and keyboard',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = FakeNutritionRepository(), kitchen = kitchenFixture();
          addTearDown(repo.journal.dispose);
          addTearDown(() => disposeKitchen(kitchen));
          await tester.pumpWidget(
            MultiRepositoryProvider(
              providers: [
                RepositoryProvider<NutritionRepository>.value(value: repo),
                RepositoryProvider<NutritionPhotoPicker>.value(
                  value: FakeNutritionPhotos(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    viewInsets: const EdgeInsets.only(bottom: 100),
                  ),
                  child: child!,
                ),
                home: KitchenScope(
                  services: kitchen,
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: const TextScaler.linear(2),
                      viewInsets: const EdgeInsets.only(bottom: 100),
                    ),
                    child: const NutritionScreen(recipeId: 'bo_ne_tieu_den'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final list = find.byType(ListView).first;
          for (var i = 0; i < 5; i++) {
            await tester.drag(list, const Offset(0, -300));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          final cubit = tester
              .element(find.text('Ước tính calo').first)
              .read<NutritionCubit>();
          cubit.reset();
          cubit.addFood(nutritionCatalogFixture().byIngredient['egg']!);
          cubit.line(0, grams: 100);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Tính calo'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Lưu bữa ăn'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final save = tester.getRect(
            find
                .ancestor(
                  of: find.text('Đã ăn · Lưu nhật ký'),
                  matching: find.byType(FilledButton),
                )
                .first,
          );
          expect(save.bottom, lessThanOrEqualTo(size.height - 100));
          await tester.tap(find.byTooltip('Đóng'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Nhật ký ăn'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
