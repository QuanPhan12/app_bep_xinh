import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/kitchen_entry_form.dart';
import '../../kitchen/widgets/recipe_picker.dart';
import '../cubits/collection_detail_cubit.dart';

class RecipeCollectionsScreen extends StatelessWidget {
  const RecipeCollectionsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        KitchenListCubit<RecipeCollection>(KitchenScope.of(context).collections)
          ..load(),
    child: const _CollectionsPage(),
  );
}

class _CollectionsPage extends StatelessWidget {
  const _CollectionsPage();
  Future<void> _edit(BuildContext context, {RecipeCollection? initial}) async {
    final cubit = context.read<KitchenListCubit<RecipeCollection>>();
    final id = initial?.id ?? kitchenId();
    final name = TextEditingController(text: initial?.name ?? '');
    await showKitchenEntryForm<RecipeCollection>(
      context,
      title: initial == null ? 'Tạo bộ sưu tập' : 'Đổi tên bộ sưu tập',
      fields: (_, _) => [kitchenInput(name, 'Tên bộ sưu tập')],
      value: () => RecipeCollection(
        id: id,
        name: kitchenText(name.text, 60),
        recipeIds: initial?.recipeIds ?? [],
      ),
      save: cubit.save,
    );
    name.dispose();
  }

  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Bộ sưu tập',
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: KitchenListBody<RecipeCollection>(
      children: (context, state) => [
        const Text(
          'Bộ sưu tập riêng tư của bạn. Xóa bộ sưu tập không bỏ lưu các món đã yêu thích.',
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Tạo bộ sưu tập',
          icon: Icons.add,
          onPressed: state.busy ? null : () => _edit(context),
        ),
        const SizedBox(height: 16),
        if (state.items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chưa có bộ sưu tập. Tạo nhóm cho những món bạn muốn nấu.',
            ),
          ),
        for (final item in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: ListTile(
                leading: const Icon(Icons.collections_bookmark_outlined),
                title: Text(item.name),
                subtitle: Text('${item.recipeIds.length} công thức'),
                onTap: () => context.push(
                  '/kitchen/collections/${Uri.encodeComponent(item.id)}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: state.busy
                      ? null
                      : (value) async {
                          if (value == 'rename') {
                            await _edit(context, initial: item);
                          } else if (await kitchenConfirmDelete(context)) {
                            if (context.mounted) {
                              await context
                                  .read<KitchenListCubit<RecipeCollection>>()
                                  .remove(item.id);
                            }
                          }
                        },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class RecipeCollectionDetailScreen extends StatelessWidget {
  final String id;
  const RecipeCollectionDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CollectionDetailCubit(KitchenScope.of(context), id)..load(),
    child: const _CollectionDetailPage(),
  );
}

class _CollectionDetailPage extends StatelessWidget {
  const _CollectionDetailPage();
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CollectionDetailCubit, CollectionDetailState>(
    listenWhen: (a, b) =>
        b.error != null && a.error != b.error && b.collection != null,
    listener: (context, state) => AppMessenger.showError(context, state.error!),
    builder: (context, state) => KitchenPage(
      title: state.collection?.name ?? 'Bộ sưu tập',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/kitchen/collections'),
      child: state.loading || state.collection == null
          ? AppLoadState(
              isLoading: state.loading,
              message: state.error,
              onRetry: context.read<CollectionDetailCubit>().load,
            )
          : AppContentScrollView(
              padding: const EdgeInsets.all(16),
              children: [
                AppButton(
                  text: 'Thêm công thức',
                  icon: Icons.add,
                  onPressed: state.busy
                      ? null
                      : () async {
                          final recipe = await showKitchenRecipePicker(context);
                          if (context.mounted && recipe != null) {
                            await context.read<CollectionDetailCubit>().add(
                              recipe.id,
                            );
                          }
                        },
                ),
                const SizedBox(height: 16),
                if (state.rows.isEmpty)
                  const Text('Bộ sưu tập chưa có công thức.'),
                for (final row in state.rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: ListTile(
                        title: Text(
                          row.recipe?.title ??
                              (row.failed
                                  ? 'Chưa tải được công thức'
                                  : 'Đang tải công thức…'),
                        ),
                        subtitle: row.failed
                            ? const Text(
                                'Món có thể đã bị gỡ hoặc mất kết nối. Bạn vẫn có thể bỏ khỏi bộ sưu tập.',
                              )
                            : null,
                        onTap: row.recipe == null
                            ? null
                            : () => context.push(
                                '/recipe/${Uri.encodeComponent(row.id)}',
                              ),
                        trailing: IconButton(
                          tooltip: 'Bỏ khỏi bộ sưu tập',
                          onPressed: state.busy
                              ? null
                              : () => context
                                    .read<CollectionDetailCubit>()
                                    .remove(row.id),
                          icon: const Icon(Icons.bookmark_remove_outlined),
                        ),
                      ),
                    ),
                  ),
                if (state.rows.any((row) => row.failed))
                  TextButton(
                    onPressed: context.read<CollectionDetailCubit>().load,
                    child: const Text('Tải lại công thức'),
                  ),
              ],
            ),
    ),
  );
}
