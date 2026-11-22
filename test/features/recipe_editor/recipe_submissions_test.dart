import 'dart:async';

import 'package:app_bep_xinh/features/recipe_editor/cubits/submissions/recipe_submissions_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_submission.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_submission_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_submissions_screen.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_text_styles.dart';

class FakeSubmissionService implements RecipeSubmissionService {
  Future<List<RecipeSubmission>> Function()? fetch;
  Future<void> Function(String)? revise;
  int reads = 0;
  Future<void> Function(RecipeSubmission, RecipeVisibilityAction)? change;
  @override
  Future<void> changeVisibility(
    RecipeSubmission expected,
    RecipeVisibilityAction action,
  ) async {
    await change?.call(expected, action);
  }

  @override
  Future<List<RecipeSubmission>> fetchOwn() async {
    reads++;
    return fetch?.call() ?? [];
  }

  @override
  Future<void> createRevision(String id) async {
    await revise?.call(id);
  }
}

RecipeSubmission item(RecipeSubmissionStatus status) => RecipeSubmission(
  id: 'r_${status.name}',
  title: 'Công thức thử nghiệm',
  cover: const RecipeImage.asset(
    id: 'photo',
    assetPath: 'assets/images/fridge_tofu_tomato.webp',
  ),
  status: status,
  submittedAt: DateTime.utc(2026, 11, 9),
  reviewReason: status == RecipeSubmissionStatus.rejected
      ? 'Cần mô tả rõ bước nấu'
      : null,
);

void main() {
  setUpAll(configureTestTextStyles);
  test(
    'visibility mutation blocks duplicate taps, reloads and preserves errors',
    () async {
      final original = item(RecipeSubmissionStatus.approved);
      final service = FakeSubmissionService()..fetch = () async => [original];
      final cubit = RecipeSubmissionsCubit(service);
      await cubit.load();
      final pending = Completer<void>();
      var calls = 0;
      service.change = (_, _) {
        calls++;
        return pending.future;
      };
      final first = cubit.changeVisibility(
        original,
        RecipeVisibilityAction.delete,
      );
      await cubit.changeVisibility(original, RecipeVisibilityAction.delete);
      expect(calls, 1);
      expect(cubit.state.editing, true);
      service.fetch = () async => [];
      pending.complete();
      await first;
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.editing, false);
      service.fetch = () async => [original];
      await cubit.load();
      service.change = (_, _) async => throw StateError('offline');
      await cubit.changeVisibility(original, RecipeVisibilityAction.hide);
      expect(cubit.state.items, [original]);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    },
  );
  testWidgets(
    'delete requires confirmation and admin-hidden post has no restore action',
    (tester) async {
      final approved = item(RecipeSubmissionStatus.approved);
      final hidden = RecipeSubmission(
        id: 'r_hidden',
        title: 'Bài admin đã ẩn',
        cover: approved.cover,
        status: RecipeSubmissionStatus.hidden,
        submittedAt: approved.submittedAt,
        visibilityRole: 'admin',
        visibilityReason: 'Cần xem xét',
      );
      var items = [hidden];
      final service = FakeSubmissionService()..fetch = () async => items;
      var changes = 0;
      service.change = (_, action) async {
        changes++;
        expect(action, RecipeVisibilityAction.delete);
        items = [];
      };
      final router = GoRouter(
        initialLocation: '/profile/submissions',
        routes: [
          GoRoute(
            path: '/profile/submissions',
            builder: (_, _) => const RecipeSubmissionsScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        RepositoryProvider<RecipeSubmissionService>.value(
          value: service,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Admin đã ẩn'), findsOneWidget);
      expect(find.text('Hiện lại bài'), findsNothing);
      final button = find.text('Xóa bài');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(changes, 0);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(changes, 0);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xóa bài'),
        ),
      );
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(find.text('Bài admin đã ẩn'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
  test(
    'submissions loads deduplicate, retry and ignore results after close',
    () async {
      final service = FakeSubmissionService();
      final pending = Completer<List<RecipeSubmission>>();
      service.fetch = () => pending.future;
      final cubit = RecipeSubmissionsCubit(service);
      final first = cubit.load();
      expect(identical(first, cubit.load()), true);
      expect(service.reads, 1);
      pending.completeError(StateError('offline'));
      await first;
      expect(cubit.state.error, isNotNull);
      service.fetch = () async => [item(RecipeSubmissionStatus.pending)];
      await cubit.load();
      expect(cubit.state.items.length, 1);
      final late = Completer<List<RecipeSubmission>>();
      service.fetch = () => late.future;
      final last = cubit.load();
      await cubit.close();
      late.complete([]);
      await last;
    },
  );
  testWidgets(
    'shows review status/reason and opens editor only after revision is created',
    (tester) async {
      final service = FakeSubmissionService()
        ..fetch = () async => [
          item(RecipeSubmissionStatus.pending),
          item(RecipeSubmissionStatus.rejected),
        ];
      final pending = Completer<void>();
      String? revised;
      service.revise = (id) {
        revised = id;
        return pending.future;
      };
      final router = GoRouter(
        initialLocation: '/profile/submissions',
        routes: [
          GoRoute(
            path: '/profile/submissions',
            builder: (_, _) => const RecipeSubmissionsScreen(),
          ),
          GoRoute(
            path: '/recipes/new',
            builder: (_, _) => const Scaffold(body: Text('Editor opened')),
          ),
        ],
      );
      await tester.pumpWidget(
        RepositoryProvider<RecipeSubmissionService>.value(
          value: service,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chờ duyệt'), findsOneWidget);
      final action = find.text('Chỉnh sửa và gửi lại');
      await tester.scrollUntilVisible(
        action,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cần mô tả rõ bước nấu'), findsOneWidget);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pump();
      expect(revised, 'r_rejected');
      expect(find.text('Editor opened'), findsNothing);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Editor opened'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
}
