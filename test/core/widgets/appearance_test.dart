import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/themes/app_theme_cubit.dart';
import 'package:app_bep_xinh/core/widgets/app_appearance_picker.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/features/home/widgets/home_feed_view.dart';

import '../../support/mock_services.dart';

class _Preference implements ThemePreference {
  String? value;
  bool fail = false;
  Future<String?> Function()? onRead;
  @override
  Future<String?> read() async => onRead == null ? value : await onRead!();
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('unavailable');
    this.value = value;
  }
}

void main() {
  testWidgets(
    'feed save retains login guard and only writes after authentication',
    (tester) async {
      var authenticated = false, prompts = 0, writes = 0;
      AppTapHandler.resetLock();
      AppTapHandler.instance.configureAuth(
        isAuthenticated: () => authenticated,
        onUnauthenticated: (_, _) => prompts++,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeRecipePost(
                recipe: homeFixture().recipes.first.copyWith(isFavorite: false),
                onOpen: () {},
                onFavorite: () => writes++,
              ),
            ),
          ),
        ),
      );
      final button = find.byTooltip('Lưu công thức');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(prompts, 1);
      expect(writes, 0);
      authenticated = true;
      AppTapHandler.resetLock();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(writes, 1);
    },
  );
  test('preference survives new session; late load cannot overwrite user selection', () async {
    final store = _Preference(), pending = Completer<String?>();
    store.onRead = () => pending.future;
    final cubit = AppThemeCubit(store);
    addTearDown(cubit.close);
    final load = cubit.load();
    await cubit.select(ThemeMode.dark);
    pending.complete('light');
    await load;
    expect(cubit.state, ThemeMode.dark);
    expect(store.value, 'dark');
    store.onRead = null;
    final restored = AppThemeCubit(store);
    addTearDown(restored.close);
    await restored.load();
    expect(restored.state, ThemeMode.dark);
    await restored.select(ThemeMode.system);
    expect(store.value, 'system');
  });
  test(
    'storage failure keeps requested appearance usable in current session',
    () async {
      final cubit = AppThemeCubit(_Preference()..fail = true);
      addTearDown(cubit.close);
      expect(await cubit.select(ThemeMode.dark), false);
      expect(cubit.state, ThemeMode.dark);
    },
  );
  test(
    'both palettes preserve brand and readable text, statuses and actions',
    () {
      double ratio(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (math.max(x, y) + .05) / (math.min(x, y) + .05);
      }

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final scheme = theme.colorScheme;
        for (final pair in [
          (scheme.onSurface, scheme.surface),
          (scheme.onSurfaceVariant, scheme.surface),
          (scheme.primary, scheme.surface),
          (Colors.white, AppColors.action),
          (scheme.onError, scheme.error),
        ]) {
          expect(ratio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
        expect(theme.textTheme.bodyMedium!.color, scheme.onSurface);
      }
      expect(AppColors.primary, const Color(0xFFE8590C));
    },
  );
  testWidgets(
    'picker changes entire app, saves choice and follows system brightness',
    (tester) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.light;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      final store = _Preference();
      final actual = AppThemeCubit(store);
      addTearDown(actual.close);
      Widget host() => BlocProvider.value(
        value: actual,
        child: BlocBuilder<AppThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: Scaffold(
              body: Column(
                children: [
                  const AppAppearancePicker(),
                  Builder(
                    builder: (context) => AppCard(
                      child: Text(
                        'Nội dung',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao diện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();
      expect(store.value, 'dark');
      expect(
        Theme.of(tester.element(find.text('Nội dung'))).brightness,
        Brightness.dark,
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(actual.state, ThemeMode.dark);
      await actual.select(ThemeMode.system);
      await tester.pumpAndSettle();
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Nội dung'))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('light and dark previews keep independent colors in one tree', (
    tester,
  ) async {
    final colors = <Color>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme])
              Theme(
                data: theme,
                child: Builder(
                  builder: (context) {
                    colors.add(context.colors.background);
                    return const SizedBox();
                  },
                ),
              ),
          ],
        ),
      ),
    );
    expect(colors, [
      AppTheme.lightTheme.colorScheme.surface,
      AppTheme.darkTheme.colorScheme.surface,
    ]);
  });
}
