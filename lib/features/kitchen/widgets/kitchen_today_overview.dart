import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../cubits/kitchen_list_cubit.dart';
import '../models/kitchen_entry.dart';
import '../services/kitchen_services.dart';

/// Tóm tắt dữ liệu đang có; dùng lại Cubit và timer của phiên, không tạo lịch mẫu.
class KitchenTodayOverview extends StatelessWidget {
  const KitchenTodayOverview({super.key});
  @override
  Widget build(BuildContext context) {
    final services = KitchenScope.maybeOf(context);
    if (services == null || !services.signedIn) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => KitchenListCubit<MealPlanEntry>(services.meals)..load(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // const AppSectionHeader(
          //   title: 'Bếp hôm nay',
          //   subtitle: 'Bữa ăn sắp tới và những việc bạn đang nấu.',
          // ),
          // const SizedBox(height: 16),
          BlocBuilder<
            KitchenListCubit<MealPlanEntry>,
            KitchenListState<MealPlanEntry>
          >(
            builder: (context, state) {
              final today = dateKey(DateTime.now());
              final meals =
                  state.items.where((e) => e.day.compareTo(today) >= 0).toList()
                    ..sort((a, b) {
                      final day = a.day.compareTo(b.day);
                      return day == 0
                          ? a.slot.index.compareTo(b.slot.index)
                          : day;
                    });
              final meal = meals.firstOrNull;
              final colors = Theme.of(context).colorScheme;
              return AppCard(
                showBorder: false,
                child: InkWell(
                  onTap: () => context.push('/kitchen/meal-plan'),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.calendarBlank,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                meal == null
                                    ? 'Thực đơn của bạn'
                                    : '${meal.day == today ? 'Hôm nay' : meal.day.split('-').reversed.take(2).join('/')} · ${meal.slot.label}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIconsRegular.caretRight,
                              size: 18,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (state.loading)
                          const LinearProgressIndicator(minHeight: 2)
                        else if (state.error != null) ...[
                          Text(
                            'Chưa tải được bữa ăn sắp tới.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: context
                                .read<KitchenListCubit<MealPlanEntry>>()
                                .load,
                            child: const Text('Thử lại'),
                          ),
                        ] else ...[
                          Text(
                            meal?.recipe.title ?? 'Hôm nay bạn muốn nấu gì?',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meal == null
                                ? 'Chọn món cho từng bữa để chuẩn bị nguyên liệu dễ hơn.'
                                : '${meal.servings} người · Chạm để xem thực đơn',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: services.timers,
            builder: (context, _) {
              final timers = services.timers.items;
              if (timers.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AppCard(
                  showBorder: false,
                  child: ListTile(
                    leading: Icon(
                      PhosphorIconsRegular.timer,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('${timers.length} đồng hồ đang theo dõi'),
                    subtitle: Text(
                      timers.first.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 18,
                    ),
                    onTap: () => context.push('/kitchen/timers'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
