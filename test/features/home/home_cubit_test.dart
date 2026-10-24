import 'dart:async';

import 'package:app_bep_xinh/features/home/cubits/home/home.dart';
import 'package:app_bep_xinh/features/home/models/home_data.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';

void main() {
  late StubHomeService service;
  late HomeCubit cubit;
  setUp(() {
    service = StubHomeService();
    cubit = HomeCubit(service: service);
  });
  tearDown(() => cubit.close());

  test('starts empty and loads all Home sections from service', () async {
    final pending = Completer<HomeData>();
    service.onFetch = () => pending.future;
    expect(cubit.state.data, isNull);
    expect(cubit.state.recipes, isEmpty);
    final loading = cubit.loadHome();
    expect(cubit.state.status, HomeStatus.loading);
    pending.complete(homeFixture());
    await loading;
    expect(cubit.state.status, HomeStatus.success);
    expect(cubit.state.data!.banners, homeFixture().banners);
    expect(cubit.state.data!.categories, homeFixture().categories);
    expect(cubit.state.recipes, homeFixture().recipes);
    expect(cubit.state.data!.fridgeSummary.readyRecipeCount, 2);
  });

  test(
    'initial failure can retry; refresh failure retains loaded content',
    () async {
      service.onFetch = () => Future.error(StateError('offline'));
      await cubit.loadHome();
      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.errorMessage, isNotNull);
      service.onFetch = null;
      await cubit.loadHome();
      expect(cubit.state.errorMessage, isNull);
      final previous = cubit.state.data;
      service.onFetch = () => Future.error(StateError('offline'));
      await cubit.refreshHome();
      expect(cubit.state.data, previous);
      expect(cubit.state.status, HomeStatus.failure);
    },
  );

  test(
    'saves favorites through service and keeps them across stale refresh',
    () async {
      await cubit.loadHome();
      final id = cubit.state.recipes.first.id;
      final calls = <(String, bool)>[];
      final saved = Completer<void>();
      service.onFavorite = (id, value) {
        calls.add((id, value));
        return saved.future;
      };
      final refresh = Completer<HomeData>();
      service.onFetch = () => refresh.future;
      final loading = cubit.refreshHome();
      final saving = cubit.toggleFavorite(id);
      await cubit.toggleFavorite(id);
      expect(calls, [(id, true)]);
      expect(cubit.state.savingFavorites, contains(id));
      saved.complete();
      await saving;
      refresh.complete(homeFixture());
      await loading;
      expect(cubit.state.recipes.first.isFavorite, isTrue);
      expect(cubit.state.savingFavorites, isEmpty);
    },
  );

  test(
    'failed favorite write leaves recipe unchanged and allows retry',
    () async {
      await cubit.loadHome();
      final id = cubit.state.recipes.first.id;
      service.onFavorite = (_, _) => Future.error(StateError('write failed'));
      await cubit.toggleFavorite(id);
      expect(cubit.state.recipes.first.isFavorite, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.savingFavorites, isEmpty);
      service.onFavorite = null;
      await cubit.toggleFavorite(id);
      expect(cubit.state.recipes.first.isFavorite, isTrue);
      expect(cubit.state.errorMessage, isNull);
    },
  );

  test('does not duplicate fetches or emit after disposal', () async {
    final pending = Completer<HomeData>();
    var calls = 0;
    service.onFetch = () {
      calls++;
      return pending.future;
    };
    final loading = cubit.loadHome();
    final duplicate = cubit.loadHome();
    expect(identical(loading, duplicate), isTrue);
    expect(calls, 1);
    await cubit.close();
    pending.complete(homeFixture());
    await expectLater(Future.wait([loading, duplicate]), completes);
  });

  test('later refresh honors authoritative server favorites', () async {
    await cubit.loadHome();
    await cubit.toggleFavorite(cubit.state.recipes.first.id);
    expect(cubit.state.recipes.first.isFavorite, isTrue);
    // Một lần đọc mới sau write có thể phản ánh cập nhật từ thiết bị khác.
    await cubit.refreshHome();
    expect(cubit.state.recipes.first.isFavorite, isFalse);
  });

  test('live fridge summary survives stale Home response and unsubscribes on close', () async {
    final updates = StreamController<FridgeSummary>.broadcast();
    service.fridgeSummaries = updates.stream;
    final home = HomeCubit(service: service);
    await home.loadHome();
    final previous = home.state.data!;
    final pending = Completer<HomeData>();
    service.onFetch = () => pending.future;
    final loading = home.refreshHome();
    final summary = FridgeSummary(
      ingredientNames: ['Thịt bò'],
      readyRecipeCount: 0,
    );
    updates.add(summary);
    await Future<void>.value();
    expect(home.state.data!.fridgeSummary, summary);
    expect(identical(home.state.data!.banners, previous.banners), isTrue);
    expect(identical(home.state.data!.recipes, previous.recipes), isTrue);
    pending.complete(homeFixture());
    await loading;
    expect(home.state.data!.fridgeSummary, summary);
    await home.close();
    expect(updates.hasListener, isFalse);
    await updates.close();
  });
}
