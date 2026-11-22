import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../recipes/widgets/recipe_content_overview.dart';
import '../../recipes/widgets/recipe_step_content.dart';
import '../../cooking_timers/screens/cooking_timers_screen.dart';
import '../services/offline_recipe_service.dart';

class OfflineRecipesState {
  final List<OfflineRecipe> items;
  final bool loading, busy;
  final String? error;
  const OfflineRecipesState({
    this.items = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });
}

class OfflineRecipesCubit extends Cubit<OfflineRecipesState> {
  final OfflineRecipeService service;
  OfflineRecipesCubit(this.service) : super(const OfflineRecipesState());
  Future<void> load() async {
    try {
      final items = await service.list();
      if (!isClosed) emit(OfflineRecipesState(items: items, loading: false));
    } catch (_) {
      if (!isClosed) {
        emit(
          const OfflineRecipesState(
            loading: false,
            error: 'Chưa đọc được dữ liệu tải về.',
          ),
        );
      }
    }
  }

  Future<void> remove(String id) async {
    if (state.busy) return;
    emit(OfflineRecipesState(items: state.items, loading: false, busy: true));
    try {
      await service.remove(id);
      await load();
    } catch (_) {
      if (!isClosed) {
        emit(
          OfflineRecipesState(
            items: state.items,
            loading: false,
            error: 'Chưa xóa được bản tải.',
          ),
        );
      }
    }
  }

  Future<void> verify(String id) async {
    if (state.busy) return;
    emit(OfflineRecipesState(items: state.items, loading: false, busy: true));
    try {
      final exists = await service.verify(id);
      if (!exists) await service.remove(id);
      await load();
      if (!isClosed) {
        emit(
          OfflineRecipesState(
            items: state.items,
            loading: false,
            error: exists
                ? 'Công thức vẫn công khai. Mở bản trực tuyến để tải phiên bản mới.'
                : 'Công thức không còn công khai; đã xóa bản tải.',
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          OfflineRecipesState(
            items: state.items,
            loading: false,
            error:
                'Chưa xác minh được kết nối. Bản tải hiện tại được giữ nguyên.',
          ),
        );
      }
    }
  }
}

class OfflineRecipesScreen extends StatelessWidget {
  const OfflineRecipesScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        OfflineRecipesCubit(KitchenScope.of(context).offline)..load(),
    child: const _OfflineList(),
  );
}

class _OfflineList extends StatelessWidget {
  const _OfflineList();
  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Công thức đã tải',
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: BlocConsumer<OfflineRecipesCubit, OfflineRecipesState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          AppMessenger.show(context, message: state.error!),
      builder: (context, state) {
        final cubit = context.read<OfflineRecipesCubit>();
        if (state.loading) return const AppLoadState(isLoading: true);
        final used = utf8
            .encode(jsonEncode(state.items.map((e) => e.toJson()).toList()))
            .length;
        return AppContentScrollView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Đã dùng ${(used / 1024).toStringAsFixed(0)} KB / ${OfflineRecipeService.maxBytes ~/ 1024} KB',
            ),
            const SizedBox(height: 12),
            const Text(
              'Bản tải chỉ để đọc và có thể cũ hơn bản trực tuyến. Chọn Tải xuống trong chi tiết món để thêm hoặc cập nhật.',
            ),
            const SizedBox(height: 16),
            if (state.items.isEmpty) const Text('Chưa tải công thức nào.'),
            for (final item in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: ListTile(
                    title: Text(item.recipe.title),
                    subtitle: Text(
                      'Cập nhật ${item.savedAt.toLocal().toString().split('.').first}',
                    ),
                    onTap: () => context.push(
                      '/kitchen/offline/${Uri.encodeComponent(item.recipe.id)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      enabled: !state.busy,
                      onSelected: (action) {
                        if (action == 'delete') {
                          cubit.remove(item.recipe.id);
                        } else {
                          cubit.verify(item.recipe.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'verify',
                          child: Text('Kiểm tra trực tuyến'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa bản tải'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (state.error != null && state.items.isEmpty)
              TextButton(
                onPressed: cubit.load,
                child: const Text('Thử đọc lại'),
              ),
          ],
        );
      },
    ),
  );
}

class OfflineRecipeScreen extends StatelessWidget {
  final String id;
  const OfflineRecipeScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        OfflineRecipesCubit(KitchenScope.of(context).offline)..load(),
    child: Builder(
      builder: (context) => KitchenPage(
        title: 'Bản tải offline',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/kitchen/offline'),
        child: BlocBuilder<OfflineRecipesCubit, OfflineRecipesState>(
          builder: (context, state) {
            if (state.loading) return const AppLoadState(isLoading: true);
            final cached = state.items
                .where((e) => e.recipe.id == id)
                .firstOrNull;
            if (cached == null) {
              return const AppLoadState(
                message: 'Không có bản tải cho món này.',
              );
            }
            final recipe = cached.recipe;
            return AppContentScrollView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Bản chỉ đọc · tải ${cached.savedAt.toLocal().toString().split('.').first}',
                ),
                const SizedBox(height: 16),
                RecipeContentOverview(content: recipe.content),
                const SizedBox(height: 20),
                Text(
                  'Nguyên liệu · ${recipe.servings} người',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final item in recipe.ingredients)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.note),
                    trailing: Text(item.quantity(1)),
                  ),
                const SizedBox(height: 20),
                for (var index = 0; index < recipe.steps.length; index++) ...[
                  RecipeStepContent(
                    step: recipe.steps[index],
                    number: index + 1,
                    total: recipe.steps.length,
                  ),
                  TextButton(
                    onPressed: () => showCookingTimerEditor(
                      context,
                      label: '${recipe.title} · Bước ${index + 1}',
                      minutes: recipe.steps[index].minutes ?? 5,
                    ),
                    child: const Text('Đặt hẹn giờ cho bước này'),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}
