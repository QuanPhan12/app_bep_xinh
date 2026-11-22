import 'dart:ui' show Tristate;
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/widgets/app_tabs.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_theme.dart' as source;

void main() {
  test('ported visual files match the reviewed Sollume snapshot', () {
    final entries = jsonDecode(
      File('docs/SOLLUME_PORT_MANIFEST.json').readAsStringSync(),
    ) as List;
    for (final entry in entries) {
      final text = File(entry['target'] as String)
          .readAsStringSync()
          .replaceAll('\r\n', '\n');
      expect(
        sha256.convert(utf8.encode(text)).toString(),
        entry['ported_sha256'],
        reason: entry['target'] as String,
      );
    }
  });
  test('facade retains original Sollume palettes and component themes', () {
    for (final pair in [
      (AppTheme.lightTheme, source.AppTheme.light),
      (AppTheme.darkTheme, source.AppTheme.dark),
    ]) {
      expect(pair.$1.colorScheme, pair.$2.colorScheme);
      expect(pair.$1.textTheme, pair.$2.textTheme);
      expect(
        pair.$1.navigationBarTheme.height,
        pair.$2.navigationBarTheme.height,
      );
      expect(
        pair.$1.navigationBarTheme.backgroundColor,
        pair.$2.navigationBarTheme.backgroundColor,
      );
      expect(
        pair.$1.navigationBarTheme.labelBehavior,
        pair.$2.navigationBarTheme.labelBehavior,
      );
      expect(
        (pair.$1.tabBarTheme.indicator as UnderlineTabIndicator).borderSide,
        (pair.$2.tabBarTheme.indicator as UnderlineTabIndicator).borderSide,
      );
      expect(pair.$1.tabBarTheme.labelStyle, pair.$2.tabBarTheme.labelStyle);
      expect(pair.$1.inputDecorationTheme, pair.$2.inputDecorationTheme);
      for (final states in [
        <WidgetState>{},
        {WidgetState.selected},
        {WidgetState.disabled},
      ]) {
        expect(
          pair.$1.navigationBarTheme.iconTheme?.resolve(states),
          pair.$2.navigationBarTheme.iconTheme?.resolve(states),
        );
        expect(
          pair.$1.navigationBarTheme.labelTextStyle?.resolve(states),
          pair.$2.navigationBarTheme.labelTextStyle?.resolve(states),
        );
        expect(
          pair.$1.filledButtonTheme.style?.backgroundColor?.resolve(states),
          pair.$2.filledButtonTheme.style?.backgroundColor?.resolve(states),
        );
        expect(
          pair.$1.filledButtonTheme.style?.minimumSize?.resolve(states),
          pair.$2.filledButtonTheme.style?.minimumSize?.resolve(states),
        );
      }
    }
  });
  testWidgets(
    'tab selection follows confirmed parent state including rejected actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var selected = 0;
      var accept = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return AppTabs(
                  labels: const ['A', 'B'],
                  selectedIndex: selected,
                  onSelected: (index) {
                    if (accept) setState(() => selected = index);
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(selected, 0);
      expect(
        tester
            .getSemantics(find.text('A'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      accept = true;
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      update(() => selected = 0);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.text('A'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
