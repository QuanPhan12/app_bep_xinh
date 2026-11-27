import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';
import '../cubits/meal_planner_cubit.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider<KitchenListCubit<MealPlanEntry>>(
        create: (_) => MealPlannerCubit(KitchenScope.of(context))..load(),
        child: const RecipeDiscoveryTheme(child: _PlannerPage()),
      );
}

class _PlannerPage extends StatefulWidget {
  const _PlannerPage();
  @override
  State<_PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<_PlannerPage> {
  late int _offset = DateTime.now().weekday - 1;
  MealPlannerCubit get _cubit =>
      context.read<KitchenListCubit<MealPlanEntry>>() as MealPlannerCubit;
  Future<void> _summary() async {
    try {
      final lines = await _cubit.summary();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nguyên liệu trong tuần'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Text(
                lines.isEmpty
                    ? 'Chưa có bữa ăn trong tuần này.'
                    : lines.map((l) => l.text).join('\n\n'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: lines.map((l) => l.text).join('\n')),
                );
                AppMessenger.showSuccess(context, 'Đã sao chép nguyên liệu.');
              },
              child: const Text('Sao chép'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        AppMessenger.showError(
          context,
          'Chưa tổng hợp được. Một món có thể không còn khả dụng hoặc mất kết nối.',
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
        final cubit = _cubit,
            day = dateKey(cubit.weekStart.add(Duration(days: _offset)));
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${i == 6 ? 'CN' : 'T${i + 2}'}\n${cubit.weekStart.add(Duration(days: i)).day}',
                        textAlign: TextAlign.center,
                      ),
                      selected: _offset == i,
                      onSelected: (_) => setState(() => _offset = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Sao chép ngày này',
                onPressed: state.busy
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: kitchenDate(day)
                              .add(const Duration(days: 1)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          await cubit.copyDay(day, dateKey(date));
                        }
                      },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
          for (final slot in MealSlot.values) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    slot.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/kitchen/meal-plan/new?day=$day&slot=${slot.name}',
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Lên bữa'),
                ),
              ],
            ),
            if (!state.items.any((e) => e.day == day && e.slot == slot))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Chưa lên bữa ăn.'),
              ),
            for (final meal in state.items.where(
              (e) => e.day == day && e.slot == slot,
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(meal.displayName),
                subtitle: Text(
                  '${meal.dishes.length} món · ${meal.servings} người\n${meal.dishes.map((d) => d.recipe.title).join(' · ')}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/kitchen/meal-plan/${meal.id}'),
              ),
          ],
          const SizedBox(height: 28),
          TextButton.icon(
            onPressed: state.busy ? null : _summary,
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Tổng hợp nguyên liệu trong tuần'),
          ),
        ];
      },
    ),
  );
}
