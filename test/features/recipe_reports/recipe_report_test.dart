import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/recipe_reports/services/recipe_report_repository.dart';
import 'package:app_bep_xinh/features/recipe_reports/cubits/recipe_report_cubit.dart';
import 'package:app_bep_xinh/features/recipe_reports/widgets/recipe_report_dialog.dart';

class FakeReports implements RecipeReportRepository {
  OwnRecipeReport? report;
  int calls = 0;
  Future<void> Function()? send;
  @override
  Future<OwnRecipeReport?> own(String id) async => report;
  @override
  Future<void> submit(String id, String category, String reason) async {
    calls++;
    await send?.call();
  }
}

void main() {
  for (final size in [const Size(390, 844), const Size(1024, 600)]) {
    testWidgets('report dialog fits $size with large text and dark theme', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeReports(), cubit = RecipeReportCubit(repo, 'r_test');
      await cubit.load();
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(body: RecipeReportDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Báo cáo món'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    });
  }
  test('report submission blocks double taps and existing reports', () async {
    final repo = FakeReports(), pending = Completer<void>();
    final cubit = RecipeReportCubit(repo, 'r_test');
    await cubit.load();
    repo.send = () => pending.future;
    final first = cubit.submit('unsafe', 'Lý do');
    await cubit.submit('spam', 'Duplicate');
    expect(repo.calls, 1);
    pending.complete();
    await first;
    expect(cubit.state.report?.status, 'open');
    await cubit.submit('spam', 'Duplicate');
    expect(repo.calls, 1);
    await cubit.close();
  });
  test(
    'failed submit preserves retry and ignores results after close',
    () async {
      final repo = FakeReports()
        ..send = () async => throw StateError('offline');
      final cubit = RecipeReportCubit(repo, 'r_test');
      await cubit.load();
      await cubit.submit('unsafe', 'Reason');
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.busy, false);
      final pending = Completer<void>();
      repo.send = () => pending.future;
      final task = cubit.submit('unsafe', 'Reason');
      await cubit.close();
      pending.complete();
      await task;
    },
  );
  testWidgets(
    'report form requires reason and shows confirmation after sending',
    (tester) async {
      final repo = FakeReports(), cubit = RecipeReportCubit(repo, 'r_test');
      await cubit.load();
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(home: const Scaffold(body: RecipeReportDialog())),
        ),
      );
      await tester.pumpAndSettle();
      final send = find.widgetWithText(TextButton, 'Gửi báo cáo');
      expect(tester.widget<TextButton>(send).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Nội dung không an toàn');
      await tester.pump();
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(find.text('Trạng thái: Chờ xử lý'), findsOneWidget);
      expect(find.text('Gửi báo cáo'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );
}
