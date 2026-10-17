import 'dart:async';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppTapHandler.resetLock();
  });

  group(
      'AppTapHandler - Chống chạm trùng đồng thời & đa chạm (Multi-touch Guard)',
      () {
    testWidgets('Chặn hành động thứ hai khi 2 nút khác nhau bị nhấn cùng lúc',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => const SizedBox(),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      var action1Executed = false;
      var action2Executed = false;

      // Giả lập user dùng 2 ngón tay nhấn đồng thời 2 nút khác nhau
      final future1 = AppTapHandler.handle(
        context,
        actionName: 'btn_action_1',
        onTap: () {
          action1Executed = true;
        },
      );

      final future2 = AppTapHandler.handle(
        context,
        actionName: 'btn_action_2',
        onTap: () {
          action2Executed = true;
        },
      );

      await Future.wait([future1, future2]);

      expect(action1Executed, isTrue);
      expect(action2Executed, isFalse);
    });

    testWidgets(
        'Chặn hành động thứ hai khi tác vụ bất đồng bộ thứ nhất đang chạy (Concurrency Lock)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => const SizedBox(),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      final completer1 = Completer<void>();
      var action2Executed = false;

      final future1 = AppTapHandler.handle(
        context,
        actionName: 'btn_async_submit',
        onTap: () => completer1.future,
      );

      final future2 = AppTapHandler.handle(
        context,
        actionName: 'btn_other_action',
        onTap: () {
          action2Executed = true;
        },
      );

      completer1.complete();
      await Future.wait([future1, future2]);

      expect(action2Executed, isFalse);
    });

    testWidgets('Cho phép thực thi khi allowConcurrent = true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => const SizedBox(),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));

      final completer1 = Completer<void>();
      var action1Executed = false;
      var action2Executed = false;

      final future1 = AppTapHandler.handle(
        context,
        actionName: 'btn_action_concurrent_1',
        allowMultiTap: true,
        allowConcurrent: true,
        onTap: () async {
          await completer1.future;
          action1Executed = true;
        },
      );

      final future2 = AppTapHandler.handle(
        context,
        actionName: 'btn_action_concurrent_2',
        allowMultiTap: true,
        allowConcurrent: true,
        onTap: () {
          action2Executed = true;
        },
      );

      completer1.complete();
      await Future.wait([future1, future2]);

      expect(action1Executed, isTrue);
      expect(action2Executed, isTrue);
    });
  });
}
