import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/cooking_timers/services/cooking_timer_service.dart';
import 'package:app_bep_xinh/features/cooking_timers/widgets/cooking_timer_card.dart';

import '../support/test_text_styles.dart';

void main() {
  const capture = bool.fromEnvironment('UI_CAPTURE_TIMER');
  setUpAll(() async {
    if (!capture) {
      configureTestTextStyles();
      return;
    }
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
    await (FontLoader('packages/phosphoricons_flutter/PhosphorRegular')
          ..addFont(
            rootBundle.load(
              'packages/phosphoricons_flutter/lib/fonts/Phosphor.ttf',
            ),
          ))
        .load();
  });
  test(
    'Timer duration survives serialization and legacy records stay compatible',
    () {
      final original = CookingTimer(
        id: 'timer',
        label: 'Luộc trứng',
        pausedMilliseconds: 120000,
        durationMilliseconds: 300000,
      );
      final restored = CookingTimer.fromJson(original.toJson());
      expect(restored.durationMilliseconds, 300000);
      final legacy = {...original.toJson()}..remove('durationMilliseconds');
      expect(CookingTimer.fromJson(legacy).durationMilliseconds, 0);
    },
  );
  testWidgets(
    'Timer card fits mobile and tablet, light/dark, hours and large text',
    (tester) async {
      final now = DateTime.utc(2026, 11, 17);
      for (final width in [320.0, 800.0]) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 2.0]) {
            for (final state in ['running', 'paused', 'finished', 'hours']) {
              tester.view.physicalSize = Size(width, 1000);
              tester.view.devicePixelRatio = 1;
              final timer = CookingTimer(
                id: state,
                label: 'Trứng lòng đào · Bước 2',
                endAt: state == 'paused'
                    ? null
                    : now.add(
                        Duration(
                          seconds: state == 'finished'
                              ? 0
                              : state == 'hours'
                              ? 5000
                              : 210,
                        ),
                      ),
                pausedMilliseconds: state == 'paused' ? 210000 : 0,
                durationMilliseconds: state == 'hours' ? 7200000 : 360000,
              );
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('timer_capture'),
                      child: Scaffold(
                        body: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: CookingTimerCard(
                                timer: timer,
                                now: now,
                                onToggle: () {},
                                onRemove: () {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                tester.getRect(find.byType(CookingTimerCard)).width,
                lessThanOrEqualTo(width),
              );
              if (capture && scale == 1 && state != 'hours') {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('timer_capture')),
                );
                await tester.runAsync(() async {
                  final image = await boundary.toImage();
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final file = File(
                    'build/ui_ux/timer_polish/${width.toInt()}_${dark ? 'dark' : 'light'}_$state.png',
                  );
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes!.buffer.asUint8List());
                  image.dispose();
                });
              }
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
