import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/kitchen_entry_form.dart';
import '../services/recipe_review_repository.dart';

class RecipeReviewsState {
  final List<RecipeReview> items;
  final RecipeReview? own;
  final RatingSummary summary;
  final String? next, error;
  final bool loading, busy;
  const RecipeReviewsState({
    this.items = const [],
    this.own,
    this.summary = const RatingSummary(),
    this.next,
    this.error,
    this.loading = true,
    this.busy = false,
  });
}

class RecipeReviewsCubit extends Cubit<RecipeReviewsState> {
  final RecipeReviewRepository repository;
  final String recipeId;
  StreamSubscription<RatingSummary>? _ratings;
  RecipeReviewsCubit(this.repository, this.recipeId)
    : super(const RecipeReviewsState());
  Future<void> load({bool more = false}) async {
    if (state.busy) return;
    final cursor = state.next;
    emit(
      RecipeReviewsState(
        items: more ? state.items : [],
        own: state.own,
        summary: state.summary,
        next: more ? cursor : null,
        loading: !more,
        busy: true,
      ),
    );
    try {
      final page = await repository.page(recipeId, after: more ? cursor : null);
      final own = repository.uid.isEmpty
          ? null
          : await repository.own(recipeId);
      if (isClosed) return;
      emit(
        RecipeReviewsState(
          items: [if (more) ...state.items, ...page.items],
          own: own,
          summary: state.summary,
          next: page.next,
          loading: false,
        ),
      );
      _ratings ??= repository
          .ratings(recipeId)
          .listen(
            (summary) {
              if (!isClosed) {
                emit(
                  RecipeReviewsState(
                    items: state.items,
                    own: state.own,
                    summary: summary,
                    next: state.next,
                    loading: state.loading,
                    busy: state.busy,
                    error: state.error,
                  ),
                );
              }
            },
            onError: (Object _, StackTrace _) {
              if (!isClosed) {
                emit(
                  RecipeReviewsState(
                    items: state.items,
                    own: state.own,
                    summary: state.summary,
                    next: state.next,
                    loading: false,
                    error: 'Chưa cập nhật được điểm đánh giá.',
                  ),
                );
              }
            },
          );
    } catch (_) {
      if (!isClosed) {
        emit(
          RecipeReviewsState(
            items: state.items,
            own: state.own,
            summary: state.summary,
            next: more ? cursor : null,
            loading: false,
            error: 'Chưa tải được đánh giá cho công thức này.',
          ),
        );
      }
    }
  }

  Future<bool> submit(int stars, String text) async {
    if (state.busy) return false;
    emit(
      RecipeReviewsState(
        items: state.items,
        own: state.own,
        summary: state.summary,
        next: state.next,
        loading: false,
        busy: true,
      ),
    );
    try {
      await repository.submit(recipeId, stars, text);
      if (isClosed) return false;
      emit(
        RecipeReviewsState(
          items: state.items,
          own: state.own,
          summary: state.summary,
          loading: false,
        ),
      );
      await load();
      return !isClosed;
    } catch (_) {
      if (!isClosed) {
        emit(
          RecipeReviewsState(
            items: state.items,
            own: state.own,
            summary: state.summary,
            loading: false,
            error: 'Chưa gửi được đánh giá. Bạn không thể tự đánh giá công thức của mình.',
          ),
        );
      }
      return false;
    }
  }

  Future<void> delete() async {
    if (state.busy) return;
    try {
      await repository.delete(recipeId);
      await load();
    } catch (_) {
      if (!isClosed) {
        emit(
          RecipeReviewsState(
            items: state.items,
            own: state.own,
            summary: state.summary,
            loading: false,
            error: 'Chưa xóa được đánh giá.',
          ),
        );
      }
    }
  }

  Future<bool> report(String uid, String reason) async {
    try {
      await repository.report(recipeId, uid, reason);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _ratings?.cancel();
    await super.close();
  }
}

class RecipeReviewsScreen extends StatelessWidget {
  final String recipeId;
  const RecipeReviewsScreen({super.key, required this.recipeId});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        RecipeReviewsCubit(KitchenScope.of(context).reviews, recipeId)..load(),
    child: const _ReviewsPage(),
  );
}

class _ReviewsPage extends StatelessWidget {
  const _ReviewsPage();
  Future<void> _edit(BuildContext context, RecipeReview? own) async {
    final cubit = context.read<RecipeReviewsCubit>();
    var stars = own?.stars ?? 5;
    final body = TextEditingController(text: own?.body ?? '');
    await showKitchenEntryForm<(int, String)>(
      context,
      title: 'Đánh giá công thức',
      fields: (_, setState) => [
        Wrap(
          spacing: 8,
          children: List.generate(
            5,
            (index) => AppChoiceChip(
              label: '${index + 1} sao',
              selected: stars == index + 1,
              onSelected: (_) => setState(() => stars = index + 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        kitchenInput(
          body,
          'Nhận xét (tùy chọn)',
          maxLength: 1000,
          lines: 4,
          required: false,
        ),
        const Text(
          'Đánh giá được kiểm tra trước khi công khai. Sửa đánh giá đã duyệt sẽ đưa về chờ duyệt và cập nhật lại điểm tổng.',
        ),
      ],
      value: () => (stars, body.text.trim()),
      save: (value) => cubit.submit(value.$1, value.$2),
    );
    body.dispose();
  }

  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Đánh giá cộng đồng',
    onBack: () => context.canPop() ? context.pop() : context.go('/home'),
    child: BlocConsumer<RecipeReviewsCubit, RecipeReviewsState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          AppMessenger.showError(context, state.error!),
      builder: (context, state) {
        final cubit = context.read<RecipeReviewsCubit>();
        if (state.loading) return const AppLoadState(isLoading: true);
        return AppContentScrollView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    PhosphorIconsFill.star,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.summary.average == null
                        ? 'Chưa có đánh giá được duyệt'
                        : '${state.summary.average!.toStringAsFixed(1)} / 5 · ${state.summary.count} đánh giá',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cubit.repository.uid.isNotEmpty)
              AppButton(
                text: state.own == null
                    ? 'Viết đánh giá'
                    : 'Sửa đánh giá của bạn',
                requiresAuth: true,
                onPressed: state.busy ? null : () => _edit(context, state.own),
              )
            else
              TextButton(
                onPressed: () => context.push(
                  '/login?from=${Uri.encodeQueryComponent('/recipe/${cubit.recipeId}/reviews')}',
                ),
                child: const Text('Đăng nhập để đánh giá'),
              ),
            if (state.own != null) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đánh giá của bạn · ${state.own!.stars} sao'),
                    Text(switch (state.own!.status) {
                      'approved' => 'Đã duyệt',
                      'hidden' => 'Đã ẩn',
                      _ => 'Chờ duyệt',
                    }),
                    if (state.own!.body.isNotEmpty) Text(state.own!.body),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () async {
                              if (await kitchenConfirmDelete(context)) {
                                await cubit.delete();
                              }
                            },
                      child: const Text('Xóa đánh giá'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            for (final review in state.items.where(
              (value) => value.uid != cubit.repository.uid,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${review.name} · ${review.stars} sao',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (review.body.isNotEmpty) Text(review.body),
                      if (cubit.repository.uid.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final reason = TextEditingController();
                              await showKitchenEntryForm<String>(
                                context,
                                title: 'Báo cáo nhận xét',
                                fields: (_, _) => [
                                  kitchenInput(
                                    reason,
                                    'Lý do',
                                    maxLength: 500,
                                    lines: 3,
                                  ),
                                ],
                                value: () => reason.text.trim(),
                                save: (value) =>
                                    cubit.report(review.uid, value),
                              );
                              reason.dispose();
                            },
                            child: const Text('Báo cáo'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (state.next != null)
              AppButton(
                text: 'Tải thêm đánh giá',
                isLoading: state.busy,
                onPressed: state.busy ? null : () => cubit.load(more: true),
              ),
            if (state.error != null)
              TextButton(
                onPressed: () => cubit.load(),
                child: const Text('Thử tải lại'),
              ),
          ],
        );
      },
    ),
  );
}
