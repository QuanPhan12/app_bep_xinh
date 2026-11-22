import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../home/models/recipe_item.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../home/widgets/home_feed_view.dart';
import '../services/following_feed_service.dart';

class FollowingCubit extends KitchenListCubit<FollowedAuthor> {
  final String uid;
  FollowingCubit(KitchenServices services)
    : uid = services.uid,
      super(services.following);
  Future<bool> follow(String authorId, String name) {
    if (authorId == uid) return Future.value(false);
    if (state.items.any((entry) => entry.id == authorId)) {
      return remove(authorId);
    }
    return run(() async {
      if (state.items.length >= 50) {
        throw const FormatException('Bạn có thể theo dõi tối đa 50 tác giả.');
      }
      await repository.save(FollowedAuthor(id: authorId, name: name));
    });
  }
}

class FollowAuthorControl extends StatelessWidget {
  final String authorId, name;
  const FollowAuthorControl({
    super.key,
    required this.authorId,
    required this.name,
  });
  @override
  Widget build(BuildContext context) {
    final services = KitchenScope.maybeOf(context);
    if (services == null || !services.signedIn || services.uid == authorId) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      create: (_) => FollowingCubit(services)..load(),
      child: BlocConsumer<FollowingCubit, KitchenListState<FollowedAuthor>>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) =>
            AppMessenger.showError(context, state.error!),
        builder: (context, state) {
          final followed = state.items.any((entry) => entry.id == authorId);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppButton(
              text: followed
                  ? 'Đang theo dõi · Bỏ theo dõi'
                  : 'Theo dõi tác giả',
              variant: AppButtonVariant.secondary,
              isLoading: state.busy,
              onPressed: state.loading || state.busy
                  ? null
                  : () => context.read<FollowingCubit>().follow(authorId, name),
            ),
          );
        },
      ),
    );
  }
}

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider<KitchenListCubit<FollowedAuthor>>(
        create: (_) => FollowingCubit(KitchenScope.of(context))..load(),
        child: const _FollowingPage(),
      );
}

class _FollowingPage extends StatelessWidget {
  const _FollowingPage();
  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Tác giả đang theo dõi',
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: KitchenListBody<FollowedAuthor>(
      children: (context, state) => [
        AppButton(
          text: 'Xem bảng tin đang theo dõi',
          onPressed: () => context.push('/kitchen/following/feed'),
        ),
        const SizedBox(height: 16),
        if (state.items.isEmpty)
          const Text(
            'Chưa theo dõi tác giả nào. Mở hồ sơ tác giả từ một công thức để bắt đầu.',
          ),
        for (final author in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: ListTile(
                title: Text(author.name),
                onTap: () =>
                    context.push('/users/${Uri.encodeComponent(author.id)}'),
                trailing: IconButton(
                  tooltip: 'Bỏ theo dõi',
                  onPressed: state.busy
                      ? null
                      : () => context
                            .read<KitchenListCubit<FollowedAuthor>>()
                            .remove(author.id),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class FollowingFeedState {
  final List<RecipeItem> items;
  final bool loading, busy, hasMore;
  final String? error;
  const FollowingFeedState({
    this.items = const [],
    this.loading = true,
    this.busy = false,
    this.hasMore = false,
    this.error,
  });
}

class FollowingFeedCubit extends Cubit<FollowingFeedState> {
  final KitchenServices services;
  final FollowingFeedService feed;
  List<FollowedAuthor> _authors = [];
  FollowingFeedCubit(this.services)
    : feed = services.createFeed(),
      super(const FollowingFeedState());
  Future<void> load({bool more = false}) async {
    if (state.busy) return;
    emit(
      FollowingFeedState(
        items: more ? state.items : [],
        loading: !more,
        busy: true,
        hasMore: state.hasMore,
      ),
    );
    try {
      if (!more) _authors = await services.following.fetch();
      final items = await feed.next(_authors, reset: !more);
      if (!isClosed) {
        emit(
          FollowingFeedState(
            items: [if (more) ...state.items, ...items],
            loading: false,
            hasMore: feed.hasMore,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          FollowingFeedState(
            items: state.items,
            loading: false,
            hasMore: state.hasMore,
            error: 'Chưa tải được bảng tin. Kiểm tra kết nối và thử lại.',
          ),
        );
      }
    }
  }
}

class FollowingFeedScreen extends StatelessWidget {
  const FollowingFeedScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FollowingFeedCubit(KitchenScope.of(context))..load(),
    child: const _FollowingFeedPage(),
  );
}

class _FollowingFeedPage extends StatelessWidget {
  const _FollowingFeedPage();
  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Đang theo dõi',
    maxWidth: 630,
    onBack: () => context.canPop() ? context.pop() : context.go('/home'),
    child: BlocBuilder<FollowingFeedCubit, FollowingFeedState>(
      builder: (context, state) {
        final cubit = context.read<FollowingFeedCubit>();
        if (state.loading) return const AppLoadState(isLoading: true);
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextButton(
                        onPressed: () => context.push('/kitchen/following'),
                        child: const Text('Quản lý tác giả đang theo dõi'),
                      ),
                      if (state.items.isEmpty)
                        const Text(
                          'Chưa có công thức. Theo dõi tác giả hoặc đợi bài mới được duyệt.',
                        ),
                      if (state.error != null)
                        TextButton(
                          onPressed: () => cubit.load(),
                          child: Text(state.error!),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final recipe = state.items[index];
                  return HomeRecipePost(
                    recipe: recipe,
                    onOpen: () => context.push(
                      '/recipe/${Uri.encodeComponent(recipe.id)}',
                    ),
                    onSource: recipe.remix == null
                        ? null
                        : () => context.push(
                            '/recipe/${Uri.encodeComponent(recipe.remix!.recipeId)}',
                          ),
                    onFavorite: null,
                    onAuthor: recipe.authorId == null
                        ? null
                        : () => context.push(
                            '/users/${Uri.encodeComponent(recipe.authorId!)}',
                          ),
                    onReview: () => context.push(
                      '/recipe/${Uri.encodeComponent(recipe.id)}/reviews',
                    ),
                  );
                },
              ),
              if (state.hasMore)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: AppButton(
                      text: 'Tải thêm',
                      isLoading: state.busy,
                      onPressed: state.busy
                          ? null
                          : () => cubit.load(more: true),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    ),
  );
}
