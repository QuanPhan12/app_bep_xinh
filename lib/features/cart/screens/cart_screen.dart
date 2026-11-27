import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../meal_planner/models/meal_session.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        KitchenListCubit<ShoppingBatch>(KitchenScope.of(context).shopping)
          ..load(),
    child: const RecipeDiscoveryTheme(child: _ShoppingPage()),
  );
}

class _ShoppingPage extends StatelessWidget {
  const _ShoppingPage();
  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Giỏ đi chợ',
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: KitchenListBody<ShoppingBatch>(
      children: (context, state) {
        final cubit = context.read<KitchenListCubit<ShoppingBatch>>();
        final lines = state.items.expand((b) => b.lines).toList();
        return [
          Text(
            'Đã chuẩn bị ${lines.where((l) => l.checked).length} trên ${lines.length} nguyên liệu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          if (lines.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Giỏ đang trống. Thêm nguyên liệu còn thiếu từ một bữa ăn.',
              ),
            ),
            TextButton(
              onPressed: () => context.push('/kitchen/meal-plan'),
              child: const Text('Lên bữa ăn'),
            ),
          ],
          for (final batch in state.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa danh sách bữa này',
                  onPressed: state.busy
                      ? null
                      : () async {
                          if (await kitchenConfirmDelete(context)) {
                            await cubit.remove(batch.id);
                          }
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            for (final line in batch.lines)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: line.checked,
                title: Text(line.name),
                subtitle: Text(line.displayQuantity),
                onChanged: state.busy
                    ? null
                    : (_) => cubit.update(
                        batch.id,
                        (current) => ShoppingBatch(
                          id: current.id,
                          title: current.title,
                          lines: [
                            for (final item in current.lines)
                              item.key == line.key ? item.toggle() : item,
                          ],
                        ),
                      ),
              ),
            const SizedBox(height: 24),
          ],
        ];
      },
    ),
  );
}
