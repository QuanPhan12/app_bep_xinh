import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/app_adaptive_columns.dart';
import '../../../core/utils/app_layout.dart';
import '../../recipes/widgets/recipe_image_view.dart';
import '../cubits/submissions/recipe_submissions_cubit.dart';
import '../models/recipe_submission.dart';
import '../services/recipe_submission_service.dart';

class RecipeSubmissionsScreen extends StatelessWidget {
  const RecipeSubmissionsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        RecipeSubmissionsCubit(context.read<RecipeSubmissionService>())..load(),
    child: const _SubmissionsPage(),
  );
}

class _SubmissionsPage extends StatelessWidget {
  const _SubmissionsPage();
  Future<void> _confirm(
    BuildContext context,
    RecipeSubmission item,
    RecipeVisibilityAction action,
  ) async {
    final label = switch (action) {
      RecipeVisibilityAction.hide => 'Ẩn bài',
      RecipeVisibilityAction.restore => 'Hiện lại bài',
      RecipeVisibilityAction.delete => 'Xóa bài',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$label?'),
        content: Text(switch (action) {
          RecipeVisibilityAction.hide => 'Bài sẽ rời danh sách công khai và banner. Bạn có thể hiện lại sau.',
          RecipeVisibilityAction.restore => 'Bài sẽ xuất hiện công khai trở lại. Banner cần được admin chọn lại.',
          RecipeVisibilityAction.delete => 'Bài sẽ bị xóa khỏi app và không thể khôi phục trong app. Lịch sử kiểm duyệt và đánh giá được giữ lại.',
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<RecipeSubmissionsCubit>().changeVisibility(
        item,
        action,
      );
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    appBar: AppSliverAppBar(
      title: 'Quản lý bài đăng',
      onBackPressed: () => context.canPop()
          ? context.pop()
          : context.go(PathRouter.profileScreen),
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.formWidth(context)),
          child: BlocConsumer<RecipeSubmissionsCubit, RecipeSubmissionsState>(
            listenWhen: (previous, next) =>
                next.editorRequest > previous.editorRequest,
            listener: (context, state) async {
              await context.push(PathRouter.recipeEditorScreen);
              if (context.mounted) {
                await context.read<RecipeSubmissionsCubit>().load();
              }
            },
            builder: (context, state) {
              final cubit = context.read<RecipeSubmissionsCubit>();
              if (state.items.isEmpty &&
                  (state.loading || state.error != null)) {
                return AppLoadState(
                  isLoading: state.loading,
                  message: state.error,
                  onRetry: cubit.load,
                );
              }
              return RefreshIndicator(
                onRefresh: cubit.load,
                child: AppContentScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Theo dõi bài chờ duyệt, sửa bài cần bổ sung và quản lý bài đã đăng.',
                    ),
                    const SizedBox(height: 16),
                    if (state.error != null)
                      TextButton(
                        onPressed: cubit.load,
                        child: Text(state.error!),
                      ),
                    if (state.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('Bạn chưa gửi công thức nào.'),
                      ),
                    for (final item in state.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppCard(
                          child: AppAdaptiveColumns(
                            breakpoint: AppLayout.tabletBreakpoint,
                            spacing: 0,
                            primaryFlex: 2,
                            secondaryFlex: 3,
                            primary: RecipeImageView(image: item.cover),
                            secondary: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  AppStatusBadge(
                                    label: switch (item.status) {
                                      RecipeSubmissionStatus.pending =>
                                        'Chờ duyệt',
                                      RecipeSubmissionStatus.approved =>
                                        'Đã duyệt',
                                      RecipeSubmissionStatus.rejected =>
                                        'Cần chỉnh sửa',
                                      RecipeSubmissionStatus.hidden =>
                                        item.visibilityRole == 'admin'
                                            ? 'Admin đã ẩn'
                                            : 'Bạn đã ẩn',
                                      RecipeSubmissionStatus.deleted =>
                                        'Đã xóa',
                                    },
                                    tone: switch (item.status) {
                                      RecipeSubmissionStatus.pending =>
                                        AppStatusTone.pending,
                                      RecipeSubmissionStatus.approved =>
                                        AppStatusTone.success,
                                      RecipeSubmissionStatus.rejected =>
                                        AppStatusTone.attention,
                                      RecipeSubmissionStatus.hidden ||
                                      RecipeSubmissionStatus.deleted =>
                                        AppStatusTone.attention,
                                    },
                                  ),
                                  if (item.reviewReason != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(item.reviewReason!),
                                    ),
                                  if (item.visibilityReason != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Lý do ẩn: ${item.visibilityReason}',
                                      ),
                                    ),
                                  if (item.status ==
                                      RecipeSubmissionStatus.approved)
                                    TextButton(
                                      onPressed: () => context.push(
                                        PathRouter.recipeDetail(item.id),
                                      ),
                                      child: const Text('Xem công thức'),
                                    ),
                                  if (item.status ==
                                      RecipeSubmissionStatus.rejected)
                                    TextButton(
                                      onPressed: state.editing
                                          ? null
                                          : () => cubit.createRevision(item.id),
                                      child: Text(
                                        state.editing
                                            ? 'Đang mở bản sửa…'
                                            : 'Chỉnh sửa và gửi lại',
                                      ),
                                    ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (item.status ==
                                          RecipeSubmissionStatus.approved)
                                        TextButton(
                                          onPressed: state.editing
                                              ? null
                                              : () => _confirm(
                                                  context,
                                                  item,
                                                  RecipeVisibilityAction.hide,
                                                ),
                                          child: const Text('Ẩn bài'),
                                        ),
                                      if (item.status ==
                                              RecipeSubmissionStatus.hidden &&
                                          item.visibilityRole == 'author')
                                        TextButton(
                                          onPressed: state.editing
                                              ? null
                                              : () => _confirm(
                                                  context,
                                                  item,
                                                  RecipeVisibilityAction
                                                      .restore,
                                                ),
                                          child: const Text('Hiện lại bài'),
                                        ),
                                      if (item.status !=
                                          RecipeSubmissionStatus.deleted)
                                        TextButton(
                                          onPressed: state.editing
                                              ? null
                                              : () => _confirm(
                                                  context,
                                                  item,
                                                  RecipeVisibilityAction.delete,
                                                ),
                                          child: Text(
                                            'Xóa bài',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (state.editing)
                                    const LinearProgressIndicator(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
