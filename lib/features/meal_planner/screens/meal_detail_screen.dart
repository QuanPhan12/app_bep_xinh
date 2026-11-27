import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_tabs.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';
import '../cubits/meal_cubit.dart';

class MealDetailScreen extends StatelessWidget {
  final String id;
  const MealDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MealCubit(KitchenScope.of(context), id)..load(),
    child: const RecipeDiscoveryTheme(child: _MealPage()),
  );
}

class _MealPage extends StatelessWidget {
  const _MealPage();
  Future<void> _finish(BuildContext context, MealCubit cubit) async {
    final timers = cubit.services.timers.items
        .where((t) => t.groupId == cubit.id)
        .length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn tất bữa ăn?'),
        content: Text(
          'Các món sẽ được lưu vào nhật ký.${timers > 0 ? ' $timers hẹn giờ của bữa này sẽ dừng.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục nấu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
    if (confirm == true) await cubit.complete();
  }

  Future<void> _consume(BuildContext context, MealCubit cubit) async {
    try {
      final deductions = await cubit.previewConsumption();
      if (!context.mounted) return;
      if (deductions.isEmpty) {
        AppMessenger.showInfo(
          context,
          'Không có lượng tồn kho tương thích để trừ.',
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận lượng đã dùng'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chỉ trừ các lô dưới đây. Nguyên liệu vừa đủ hoặc khác đơn vị cần bạn tự cập nhật trong kho.',
                  ),
                  const SizedBox(height: 12),
                  for (final d in deductions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${d.lot.name}: ${d.quantity}'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đã dùng, trừ kho'),
            ),
          ],
        ),
      );
      if (confirmed == true) await cubit.consume(deductions);
    } catch (_) {
      if (context.mounted) {
        AppMessenger.showError(
          context,
          'Chưa tải được tồn kho. Vui lòng thử lại.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<MealCubit, MealState>(
    listener: (context, state) {
      if (state.error != null && state.meal != null) {
        AppMessenger.showError(context, state.error!);
      }
    },
    builder: (context, state) {
      final cubit = context.read<MealCubit>(),
          meal = state.meal,
          session = state.session;
      return KitchenPage(
        title: meal?.displayName ?? 'Bữa ăn',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/kitchen/meal-plan'),
        actions: meal == null
            ? null
            : [
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn bữa ăn',
                  enabled: !state.busy,
                  onSelected: (action) async {
                    if (action == 'nutrition') {
                      context.push('/kitchen/nutrition?meal=${meal.id}');
                    } else if (action == 'refresh') {
                      await cubit.run(cubit.load);
                    } else if (action == 'delete') {
                      if (await kitchenConfirmDelete(context) &&
                          await cubit.delete() &&
                          context.mounted) {
                        context.go('/kitchen/meal-plan');
                      }
                    } else {
                      context.push(
                        action == 'edit'
                            ? '/kitchen/meal-plan/${meal.id}/edit'
                            : '/kitchen/meal-plan/new?copy=${meal.id}',
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'nutrition',
                      child: Text('Ước tính calo'),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Text('Tải lại'),
                    ),
                    if (session == null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa bữa ăn'),
                      ),
                    if (session == null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Sửa bữa ăn'),
                      ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Dùng lại bữa này'),
                    ),
                  ],
                ),
              ],
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : meal == null || state.recipes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error ?? 'Không tìm thấy bữa ăn.'),
                      TextButton(
                        onPressed: cubit.load,
                        child: const Text('Thử lại'),
                      ),
                      if (meal != null)
                        TextButton(
                          onPressed: () => context.push(
                            session == null
                                ? '/kitchen/meal-plan/${meal.id}/edit'
                                : '/kitchen/meal-plan/new?copy=${meal.id}',
                          ),
                          child: Text(
                            session == null
                                ? 'Sửa các món trong bữa'
                                : 'Dùng lại thành bữa mới',
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${meal.day} · ${meal.slot.label} · ${meal.servings} người · ${meal.dishes.length} món',
                      ),
                    ),
                  ),
                  AppTabs(
                    labels: const ['Bữa ăn', 'Nguyên liệu', 'Nấu bữa'],
                    selectedIndex: state.tab,
                    onSelected: cubit.selectTab,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (state.tab == 0) ...[
                          for (final dish in meal.dishes)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(dish.recipe.title),
                              subtitle: Text(
                                '${dish.role.label} · ${(state.recipes[dish.recipe.id]!.preparationMinutes + state.recipes[dish.recipe.id]!.cookingMinutes)} phút',
                              ),
                              trailing: Icon(
                                session?.done.contains(dish.recipe.id) == true
                                    ? Icons.check
                                    : Icons.chevron_right,
                              ),
                              onTap: () => context.push(
                                '/recipe/${Uri.encodeComponent(dish.recipe.id)}',
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'Gợi ý thứ tự bắt đầu',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ..._order(state).indexed.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                '${entry.$1 + 1}. ${state.recipes[entry.$2]!.title}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ưu tiên món có tổng thời gian chuẩn bị và nấu dài hơn. Bạn chủ động sắp xếp bếp và các bước có thể làm cùng lúc.',
                          ),
                        ],
                        if (state.tab == 1) ...[
                          const Text(
                            'Khẩu phần đã tính cho cả bữa. Đánh dấu khi bạn đã kiểm tra và có đủ nguyên liệu.',
                          ),
                          const SizedBox(height: 12),
                          for (final line in state.ingredients)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: meal.preparedKeys.contains(line.key),
                              onChanged: state.busy
                                  ? null
                                  : (value) => cubit.prepared(
                                      line.key,
                                      value ?? false,
                                    ),
                              title: Text(line.name),
                              subtitle: Text(
                                '${line.quantity()}${state.fridgeIds.contains(line.ingredientId) ? ' · Có trong tủ lạnh, kiểm tra lượng' : ''}',
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'Cần mua · ${cubit.missing.length} nguyên liệu',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          for (final line in cubit.missing)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(line.name),
                              subtitle: Text(line.quantity),
                            ),
                          TextButton.icon(
                            onPressed: state.busy
                                ? null
                                : () async {
                                    if (await cubit.addShopping() &&
                                        context.mounted) {
                                      AppMessenger.showSuccess(
                                        context,
                                        'Đã cập nhật nguyên liệu thiếu vào giỏ đi chợ.',
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Cập nhật giỏ đi chợ'),
                          ),
                          TextButton(
                            onPressed: () => context.push('/cart'),
                            child: const Text('Mở giỏ đi chợ'),
                          ),
                        ],
                        if (state.tab == 2) ...[
                          if (session == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Bắt đầu nấu để lưu tiến độ riêng cho từng món.',
                              ),
                            )
                          else if (session.completed) ...[
                            Text(
                              'Bữa ăn đã hoàn tất',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Các món đã được lưu trong nhật ký nấu ăn.',
                            ),
                            TextButton(
                              onPressed: () => context.push('/kitchen/journal'),
                              child: const Text('Xem nhật ký'),
                            ),
                            if (!session.pantryConsumed)
                              TextButton(
                                onPressed: state.busy
                                    ? null
                                    : () => _consume(context, cubit),
                                child: const Text(
                                  'Xem lượng đã dùng và trừ kho',
                                ),
                              )
                            else
                              const Text('Đã cập nhật tồn kho cho bữa này.'),
                          ] else ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final dish in meal.dishes)
                                  ChoiceChip(
                                    label: Text(
                                      '${session.done.contains(dish.recipe.id) ? '✓ ' : ''}${dish.recipe.title}',
                                    ),
                                    selected:
                                        session.selectedRecipeId ==
                                        dish.recipe.id,
                                    onSelected: state.busy
                                        ? null
                                        : (_) => cubit.progress(
                                            selected: dish.recipe.id,
                                          ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ..._step(context, cubit, state),
                          ],
                          const SizedBox(height: 16),
                          _MealTimers(cubit: cubit),
                        ],
                      ],
                    ),
                  ),
                  if (session?.completed != true)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.busy
                              ? null
                              : session == null
                              ? cubit.start
                              : session.done.length == meal.dishes.length
                              ? () => _finish(context, cubit)
                              : () {
                                  cubit.selectTab(2);
                                },
                          child: Text(
                            state.busy
                                ? 'Đang lưu…'
                                : session == null
                                ? 'Bắt đầu nấu bữa'
                                : session.done.length == meal.dishes.length
                                ? 'Hoàn tất bữa ăn'
                                : 'Tiếp tục nấu · ${session.done.length}/${meal.dishes.length} món',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );
  List<String> _order(MealState state) => state.recipes.keys.toList()
    ..sort(
      (a, b) =>
          (state.recipes[b]!.preparationMinutes +
                  state.recipes[b]!.cookingMinutes)
              .compareTo(
                state.recipes[a]!.preparationMinutes +
                    state.recipes[a]!.cookingMinutes,
              ),
    );
  List<Widget> _step(BuildContext context, MealCubit cubit, MealState state) {
    final session = state.session!,
        recipe = state.recipes[session.selectedRecipeId]!;
    final index = (session.steps[recipe.id] ?? 0).clamp(
          0,
          recipe.steps.length - 1,
        ),
        step = recipe.steps[index];
    final done = session.done.contains(recipe.id);
    return [
      Text(recipe.title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(
        'Bước ${index + 1}/${recipe.steps.length}${step.title.isNotEmpty ? ' · ${step.title}' : ''}',
      ),
      const SizedBox(height: 12),
      Text(
        step.instruction,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
      if (step.tip.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(step.tip)),
      if (step.minutes != null)
        TextButton.icon(
          onPressed: state.busy || done
              ? null
              : () => cubit.timer(recipe, index),
          icon: const Icon(Icons.timer_outlined),
          label: Text('Hẹn giờ ${step.minutes} phút'),
        ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (index > 0)
            TextButton(
              onPressed: state.busy
                  ? null
                  : () => cubit.progress(step: index - 1),
              child: const Text('Bước trước'),
            ),
          if (index < recipe.steps.length - 1)
            TextButton(
              onPressed: state.busy || done
                  ? null
                  : () => cubit.progress(step: index + 1),
              child: const Text('Bước tiếp theo'),
            ),
          if (index == recipe.steps.length - 1 || done)
            TextButton.icon(
              onPressed: state.busy ? null : () => cubit.progress(done: !done),
              icon: Icon(done ? Icons.undo : Icons.check),
              label: Text(done ? 'Nấu tiếp món này' : 'Xong món này'),
            ),
        ],
      ),
    ];
  }
}

class _MealTimers extends StatelessWidget {
  final MealCubit cubit;
  const _MealTimers({required this.cubit});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cubit.services.timers,
    builder: (context, _) {
      final timers = cubit.services.timers;
      final items = timers.items.where((t) => t.groupId == cubit.id).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isNotEmpty)
            Text(
              'Hẹn giờ của bữa',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          for (final timer in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(timer.label),
              subtitle: Text(
                timer.remaining(timers.now()).inSeconds == 0
                    ? 'Đã hết giờ'
                    : '${timer.remaining(timers.now()).inMinutes}:${(timer.remaining(timers.now()).inSeconds % 60).toString().padLeft(2, '0')}${timer.paused ? ' · Tạm dừng' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: timer.paused ? 'Tiếp tục' : 'Tạm dừng',
                    onPressed: cubit.state.busy
                        ? null
                        : () => cubit.run(() => timers.toggle(timer.id)),
                    icon: Icon(timer.paused ? Icons.play_arrow : Icons.pause),
                  ),
                  IconButton(
                    tooltip: 'Dừng hẹn giờ',
                    onPressed: cubit.state.busy
                        ? null
                        : () => cubit.run(() => timers.remove(timer.id)),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
