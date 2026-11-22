import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../../core/utils/app_layout.dart';
import '../../recipes/widgets/recipe_remix_attribution.dart';
import '../services/recipe_remix_service.dart';
import '../services/recipe_authoring_repository.dart';
import '../models/recipe_draft.dart';

class RecipeRemixState {
  const RecipeRemixState({this.seed, this.error, this.editing = false});
  final RecipeRemixSeed? seed;
  final String? error;
  final bool editing;
}

class RecipeRemixCubit extends Cubit<RecipeRemixState> {
  RecipeRemixCubit(this.service, this.id) : super(const RecipeRemixState());
  final RecipeRemixService service;
  final String id;
  Future<void>? _task;
  Future<void> load() => _task ??= _load().whenComplete(() => _task = null);
  Future<void> _load() async {
    emit(const RecipeRemixState());
    try {
      final seed = await service.load(id);
      if (!isClosed) emit(RecipeRemixState(seed: seed));
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          RecipeRemixState(
            error: error is RecipeAuthoringException
                ? error.message
                : 'Không tải được công thức gốc. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  void start() {
    if (state.seed != null) {
      emit(RecipeRemixState(seed: state.seed, editing: true));
    }
  }
}

class RecipeRemixGate extends StatelessWidget {
  const RecipeRemixGate({
    super.key,
    required this.service,
    required this.recipeId,
    required this.editorBuilder,
  });
  final RecipeRemixService service;
  final String recipeId;
  final Widget Function(RecipeDraft, RecipeDraft?) editorBuilder;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RecipeRemixCubit(service, recipeId)..load(),
    child: BlocBuilder<RecipeRemixCubit, RecipeRemixState>(
      builder: (context, state) {
        final seed = state.seed;
        if (state.editing && seed != null) {
          return editorBuilder(seed.draft, seed.previous);
        }
        return AppPageScaffold(
          appBar: AppSliverAppBar(
            title: 'Biến tấu công thức',
            onBackPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppLayout.formWidth(context),
              ),
              child: seed == null
                  ? AppLoadState(
                      isLoading: state.error == null,
                      message: state.error,
                      onRetry: context.read<RecipeRemixCubit>().load,
                    )
                  : AppContentScrollView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'Nấu theo cách của bạn',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chỉnh nguyên liệu, định lượng hoặc cách nấu rồi chia sẻ phiên bản của bạn. Công thức gốc được ghi nguồn và bài mới vẫn cần duyệt.',
                        ),
                        const SizedBox(height: 24),
                        RecipeRemixAttribution(
                          remix: seed.draft.remix!,
                          showChanges: false,
                          onOpen: () => context.push(
                            '/recipe/${Uri.encodeComponent(recipeId)}',
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (seed.replacesDraft) ...[
                          Text(
                            'Bạn đang có bản nháp khác',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bản nháp hiện tại chỉ bị thay khi bạn lưu hoặc gửi bản biến tấu.',
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppButton(
                          text: seed.previous?.remix?.recipeId == recipeId
                              ? 'Tiếp tục bản biến tấu'
                              : 'Bắt đầu chỉnh sửa',
                          onPressed: () async {
                            final cubit = context.read<RecipeRemixCubit>();
                            if (seed.replacesDraft) {
                              final approved = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text(
                                    'Chuyển sang bản biến tấu?',
                                  ),
                                  content: const Text(
                                    'Lưu hoặc gửi bản biến tấu sẽ thay bản nháp đang có. Bạn có thể giữ nháp hiện tại và quay lại sau.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Giữ bản nháp'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Tiếp tục'),
                                    ),
                                  ],
                                ),
                              );
                              if (approved != true) return;
                            }
                            if (!cubit.isClosed) cubit.start();
                          },
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    ),
  );
}
