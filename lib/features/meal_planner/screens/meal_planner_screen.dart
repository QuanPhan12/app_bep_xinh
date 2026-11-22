import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/kitchen_entry_form.dart';
import '../../kitchen/widgets/recipe_picker.dart';
import '../cubits/meal_planner_cubit.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider<KitchenListCubit<MealPlanEntry>>(
        create: (_) => MealPlannerCubit(KitchenScope.of(context))..load(),
        child: const _PlannerPage(),
      );
}

class _PlannerPage extends StatelessWidget {
  const _PlannerPage();
  MealPlannerCubit _cubit(BuildContext context) =>
      context.read<KitchenListCubit<MealPlanEntry>>() as MealPlannerCubit;
  Future<void> _edit(
    BuildContext context,
    String day,
    MealSlot slot, {
    MealPlanEntry? initial,
  }) async {
    final cubit = _cubit(context);
    RecipeRef? recipe = initial?.recipe;
    var selectedDay = day;
    var selectedSlot = slot;
    final servings = TextEditingController(text: '${initial?.servings ?? 2}');
    await showKitchenEntryForm<MealPlanEntry>(
      context,
      title: initial == null ? 'Thêm món vào thực đơn' : 'Sửa bữa ăn',
      fields: (formContext, setState) => [
        ListTile(
          title: Text(recipe?.title ?? 'Chọn công thức'),
          trailing: const Icon(Icons.restaurant_menu),
          onTap: () async {
            final next = await showKitchenRecipePicker(context);
            if (formContext.mounted && next != null) {
              setState(() => recipe = RecipeRef.fromRecipe(next));
            }
          },
        ),
        ListTile(
          title: Text('Ngày: $selectedDay'),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final date = await showDatePicker(
              context: formContext,
              initialDate: kitchenDate(selectedDay),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (formContext.mounted && date != null) {
              setState(() => selectedDay = dateKey(date));
            }
          },
        ),
        DropdownButtonFormField<MealSlot>(
          initialValue: selectedSlot,
          decoration: const InputDecoration(labelText: 'Bữa ăn'),
          items: MealSlot.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => selectedSlot = value);
          },
        ),
        const SizedBox(height: 16),
        kitchenInput(servings, 'Số người ăn', number: true, maxLength: 2),
      ],
      value: () {
        if (recipe == null) throw const FormatException('Chọn một công thức.');
        return MealPlanEntry(
          id: initial?.id ?? kitchenId(),
          day: selectedDay,
          slot: selectedSlot,
          recipe: recipe!,
          servings: kitchenInt(int.tryParse(servings.text), 1, 50),
        );
      },
      save: (entry) => cubit.run(() => cubit.repository.save(entry)),
    );
    servings.dispose();
  }

  Future<void> _summary(BuildContext context) async {
    final cubit = _cubit(context);
    try {
      final lines = await cubit.summary();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nguyên liệu trong tuần'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: lines.isEmpty
                    ? [const Text('Chưa có món trong tuần này.')]
                    : lines
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(line.text),
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: lines.map((line) => line.text).join('\n'),
                  ),
                );
                if (dialogContext.mounted) {
                  AppMessenger.showSuccess(
                    dialogContext,
                    'Đã sao chép danh sách nguyên liệu.',
                  );
                }
              },
              child: const Text('Sao chép'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppMessenger.showError(
          context,
          'Chưa tổng hợp được nguyên liệu. Một món có thể không còn khả dụng hoặc mất kết nối.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Thực đơn tuần',
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: KitchenListBody<MealPlanEntry>(
      children: (context, state) {
        final cubit = _cubit(context);
        return [
          Row(
            children: [
              IconButton(
                tooltip: 'Tuần trước',
                onPressed: () => cubit.moveWeek(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${dateKey(cubit.weekStart)} — ${dateKey(cubit.weekStart.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: 'Tuần sau',
                onPressed: () => cubit.moveWeek(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Tổng hợp nguyên liệu',
            onPressed: state.busy ? null : () => _summary(context),
            variant: AppButtonVariant.secondary,
          ),
          const SizedBox(height: 16),
          for (var offset = 0; offset < 7; offset++) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateKey(cubit.weekStart.add(Duration(days: offset))),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sao chép ngày này',
                        onPressed: state.busy
                            ? null
                            : () async {
                                final sourceDay = dateKey(
                                  cubit.weekStart.add(Duration(days: offset)),
                                );
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: kitchenDate(sourceDay)
                                      .add(const Duration(days: 1)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  await cubit.copyDay(sourceDay, dateKey(date));
                                }
                              },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                  for (final slot in MealSlot.values) ...[
                    Row(
                      children: [
                        Expanded(child: Text(slot.label)),
                        IconButton(
                          tooltip: 'Thêm ${slot.label.toLowerCase()}',
                          onPressed: state.busy
                              ? null
                              : () => _edit(
                                  context,
                                  dateKey(
                                    cubit.weekStart.add(Duration(days: offset)),
                                  ),
                                  slot,
                                ),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    for (final entry in state.items.where(
                      (e) =>
                          e.day ==
                              dateKey(
                                cubit.weekStart.add(Duration(days: offset)),
                              ) &&
                          e.slot == slot,
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.recipe.title),
                        subtitle: Text('${entry.servings} người'),
                        onTap: () => context.push(
                          '/recipe/${Uri.encodeComponent(entry.recipe.id)}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await _edit(
                                context,
                                entry.day,
                                entry.slot,
                                initial: entry,
                              );
                            } else if (await kitchenConfirmDelete(context)) {
                              await cubit.run(
                                () => cubit.repository.delete(entry.id),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Danh sách nguyên liệu chỉ để xem và sao chép; giỏ đi chợ giữ nguyên phạm vi hiện tại.',
          ),
        ];
      },
    ),
  );
}
