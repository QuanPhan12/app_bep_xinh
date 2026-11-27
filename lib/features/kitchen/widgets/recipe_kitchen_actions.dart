import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../cooking_journal/screens/cooking_journal_screen.dart';
import '../../recipe_detail/models/recipe_detail.dart';
import '../cubits/kitchen_list_cubit.dart';
import '../models/kitchen_entry.dart';
import '../services/kitchen_services.dart';
import 'kitchen_entry_form.dart';
import 'kitchen_page.dart';

Future<void> showAddMealFromRecipe(
  BuildContext context,
  RecipeRef recipe,
  int initialServings,
) async {
  final services = KitchenScope.of(context);
  final cubit = KitchenListCubit<MealPlanEntry>(services.meals);
  var existing = <MealPlanEntry>[];
  try {
    final sessions = await services.mealSessions.fetch();
    final locked = sessions.map((s) => s.id).toSet();
    existing = (await services.meals.fetch())
        .where(
          (m) =>
              !locked.contains(m.id) &&
              m.dishes.length < 6 &&
              !m.dishes.any((d) => d.recipe.id == recipe.id) &&
              m.day.compareTo(dateKey(DateTime.now())) >= 0,
        )
        .toList();
  } catch (_) {
    /* Tạo bữa mới vẫn dùng được khi danh sách chưa tải thành công. */
  }
  if (!context.mounted) {
    await cubit.close();
    return;
  }
  MealPlanEntry? selected;
  final id = kitchenId();
  var day = dateKey(DateTime.now());
  var slot = MealSlot.dinner;
  final servings = TextEditingController(text: '$initialServings');
  await showKitchenEntryForm<MealPlanEntry>(
    context,
    title: 'Thêm vào thực đơn',
    fields: (formContext, setState) => [
      Text(recipe.title, style: Theme.of(formContext).textTheme.titleMedium),
      if (existing.isNotEmpty)
        DropdownButtonFormField<String>(
          initialValue: 'new',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Thêm vào bữa'),
          items: [
            const DropdownMenuItem(value: 'new', child: Text('Tạo bữa mới')),
            for (final meal in existing)
              DropdownMenuItem(
                value: meal.id,
                child: Text(
                  '${meal.day} · ${meal.displayName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) => setState(
            () => selected = existing.where((m) => m.id == id).firstOrNull,
          ),
        ),
      if (selected != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${selected!.day} · ${selected!.slot.label} · ${selected!.servings} người. Món được tính theo khẩu phần của bữa.',
          ),
        ),
      if (selected == null) ...[
        ListTile(
          title: Text('Ngày: $day'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final date = await showDatePicker(
              context: formContext,
              initialDate: kitchenDate(day),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (formContext.mounted && date != null) {
              setState(() => day = dateKey(date));
            }
          },
        ),
        DropdownButtonFormField<MealSlot>(
          initialValue: slot,
          items: MealSlot.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => slot = value);
          },
        ),
        const SizedBox(height: 16),
        kitchenInput(servings, 'Số người ăn', maxLength: 2, number: true),
      ],
    ],
    value: () => selected != null
        ? selected!.copyWith(
            dishes: [
              ...selected!.dishes,
              MealDish(recipe: recipe),
            ],
            preparedKeys: const [],
          )
        : MealPlanEntry(
            id: id,
            day: day,
            slot: slot,
            dishes: [MealDish(recipe: recipe)],
            servings: kitchenInt(int.tryParse(servings.text), 1, 50),
          ),
    save: (entry) => selected == null
        ? cubit.save(entry)
        : cubit.update(entry.id, (current) {
            if (current.dishes.any((d) => d.recipe.id == recipe.id)) {
              return current;
            }
            return current.copyWith(
              dishes: [
                ...current.dishes,
                MealDish(recipe: recipe),
              ],
              preparedKeys: const [],
            );
          }),
  );
  servings.dispose();
  await cubit.close();
}

Future<void> showRecipeCollectionChooser(
  BuildContext context,
  String recipeId,
) async {
  final services = KitchenScope.of(context);
  await showAppAdaptiveSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) =>
          KitchenListCubit<RecipeCollection>(services.collections)..load(),
      child: Builder(
        builder: (context) => SizedBox(
          height: 480,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Lưu vào bộ sưu tập')),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: KitchenListBody<RecipeCollection>(
                    children: (context, state) => [
                      if (state.items.isEmpty)
                        const Text(
                          'Bạn chưa có bộ sưu tập. Tạo một nhóm trong Bếp của tôi.',
                        ),
                      for (final item in state.items)
                        ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            item.recipeIds.contains(recipeId)
                                ? 'Đã có công thức này'
                                : '${item.recipeIds.length} công thức',
                          ),
                          enabled:
                              !state.busy && !item.recipeIds.contains(recipeId),
                          onTap: () async {
                            final saved = await context
                                .read<KitchenListCubit<RecipeCollection>>()
                                .update(
                                  item.id,
                                  (current) => RecipeCollection(
                                    id: current.id,
                                    name: current.name,
                                    recipeIds: {
                                      ...current.recipeIds,
                                      recipeId,
                                    }.toList(),
                                  ),
                                );
                            if (context.mounted && saved) {
                              AppMessenger.showSuccess(
                                context,
                                'Đã thêm vào bộ sưu tập.',
                              );
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CookingJournalCompletionAction extends StatefulWidget {
  final RecipeDetail recipe;
  final String sessionId;
  final int servings;
  const CookingJournalCompletionAction({
    super.key,
    required this.recipe,
    required this.sessionId,
    required this.servings,
  });
  @override
  State<CookingJournalCompletionAction> createState() => _CompletionState();
}

class _CompletionState extends State<CookingJournalCompletionAction> {
  bool saved = false;
  @override
  Widget build(BuildContext context) {
    if (!(KitchenScope.maybeOf(context)?.signedIn ?? false)) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 12,
      children: [
        TextButton(
          onPressed: saved
              ? null
              : () async {
                  final success = await showCookingLogEditor(
                    context,
                    recipe: RecipeRef.fromRecipe(widget.recipe),
                    sessionId: widget.sessionId,
                    servings: widget.servings,
                  );
                  if (mounted && success) setState(() => saved = true);
                },
          child: Text(saved ? 'Đã lưu lần nấu' : 'Lưu lần nấu vào nhật ký'),
        ),
        if (saved)
          TextButton(
            onPressed: () => context.push('/kitchen/pantry'),
            child: const Text('Điều chỉnh lượng nguyên liệu đã dùng'),
          ),
      ],
    );
  }
}
