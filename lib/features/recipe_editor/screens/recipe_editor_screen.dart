import 'package:app_bep_xinh/core/colors/app_colors.dart';

import '../widgets/recipe_editor_skeleton.dart';

import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/widgets/app_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../services/recipe_cover_picker.dart';
import '../services/recipe_editor_service.dart';
import '../widgets/recipe_editor_actions.dart';
import '../widgets/recipe_editor_form.dart';

class RecipeEditorScreen extends StatelessWidget {
  const RecipeEditorScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => RecipeEditorCubit(
      service: context.read<RecipeEditorService>(),
      coverPicker: context.read<RecipeCoverPicker>(),
    )..loadDraft(),
    child: const _RecipeEditorPage(),
  );
}

class _RecipeEditorPage extends StatelessWidget {
  const _RecipeEditorPage();

  Future<void> _leave(BuildContext context) async {
    final approved = await context.read<RecipeEditorCubit>().requestExit(
      () async =>
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Rời màn hình?'),
              content: const Text(
                'Các thay đổi chưa lưu sẽ bị bỏ. Bạn có thể quay lại để lưu nháp.',
              ),
              actions: [
                TextButton(
                  onPressed: dialogContext.onAppTap(
                    () => Navigator.of(dialogContext).pop(false),
                    actionName: 'recipe_keep_editing',
                    allowConcurrent: true,
                  ),
                  child: const Text('Ở lại'),
                ),
                TextButton(
                  onPressed: dialogContext.onAppTap(
                    () => Navigator.of(dialogContext).pop(true),
                    actionName: 'recipe_discard',
                    allowConcurrent: true,
                  ),
                  child: const Text('Bỏ thay đổi'),
                ),
              ],
            ),
          ) ??
          false,
    );
    if (!context.mounted || !approved) return;
    // Để PopScope nhận canLeave mới trước khi thực hiện pop từ nút Back/hệ thống.
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) _pop(context);
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PathRouter.homeScreen);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RecipeEditorCubit, RecipeEditorState>(
    listenWhen: (previous, current) =>
        previous.noticeId != current.noticeId ||
        (previous.status != current.status &&
            current.status == RecipeEditorStatus.submitted),
    listener: (context, state) {
      final submitted = state.status == RecipeEditorStatus.submitted;
      final message = submitted ? 'Đã gửi công thức chờ duyệt.' : state.message;
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
      if (submitted) _pop(context);
    },
    buildWhen: (previous, current) =>
        previous.status != current.status ||
        previous.canLeave != current.canLeave ||
        previous.isBusy != current.isBusy,
    builder: (context, state) {
      final ready =
          state.status == RecipeEditorStatus.ready ||
          state.status == RecipeEditorStatus.submitted;
      return PopScope(
        canPop: state.canLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave(context);
        },
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppAppBar(
            title: 'Đăng món',
            backEnabled: !state.isBusy,
            onBack: () => _leave(context),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: ready
                    ? const RecipeEditorForm()
                    : AppLoadState(
                        skeleton: const RecipeEditorSkeleton(),
                        isLoading:
                            state.status != RecipeEditorStatus.loadFailure,
                        message: state.message,
                        onRetry: context.read<RecipeEditorCubit>().loadDraft,
                      ),
              ),
            ),
          ),
          bottomNavigationBar: ready ? const RecipeEditorActions() : null,
        ),
      );
    },
  );
}
