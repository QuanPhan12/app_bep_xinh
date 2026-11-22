import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../ingredients/models/ingredient_catalog.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/kitchen_entry_form.dart';
import '../cubits/pantry_cubit.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider<KitchenListCubit<PantryLot>>(
        create: (_) => PantryCubit(KitchenScope.of(context))..load(),
        child: const _PantryPage(),
      );
}

class _PantryPage extends StatelessWidget {
  const _PantryPage();
  PantryCubit _cubit(BuildContext context) =>
      context.read<KitchenListCubit<PantryLot>>() as PantryCubit;
  Future<void> _edit(BuildContext context, {PantryLot? initial}) async {
    final cubit = _cubit(context);
    IngredientCatalog catalog;
    try {
      catalog = await cubit.loadCatalog();
    } catch (_) {
      if (context.mounted) {
        AppMessenger.showError(context, 'Chưa tải được danh mục nguyên liệu.');
      }
      return;
    }
    if (!context.mounted) return;
    var ingredient = initial == null
        ? null
        : catalog.byId[initial.ingredientId];
    String? unitId = initial?.unitId ?? ingredient?.preferredUnitId;
    String? expires = initial?.expiresOn;
    final amount = TextEditingController(
      text: initial?.amount?.toString() ?? '',
    );
    final id = initial?.id ?? kitchenId();
    await showKitchenEntryForm<PantryLot>(
      context,
      title: initial == null ? 'Thêm lô nguyên liệu' : 'Sửa lô nguyên liệu',
      fields: (formContext, setState) => [
        DropdownMenu<Ingredient>(
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          enableSearch: true,
          label: const Text('Tìm nguyên liệu'),
          initialSelection: ingredient,
          dropdownMenuEntries: catalog.ingredients
              .map((item) => DropdownMenuEntry(value: item, label: item.name))
              .toList(),
          onSelected: (next) {
            if (next != null) {
              setState(() {
                ingredient = next;
                unitId = next.preferredUnitId;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        kitchenInput(
          amount,
          'Số lượng (bỏ trống nếu chưa biết)',
          number: true,
          required: false,
          maxLength: 12,
        ),
        if (ingredient != null)
          DropdownButtonFormField<String>(
            key: ValueKey(ingredient!.id),
            initialValue: unitId,
            decoration: const InputDecoration(labelText: 'Đơn vị'),
            items: ingredient!.unitIds
                .where(catalog.unitsById.containsKey)
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(catalog.unitsById[id]!.label),
                  ),
                )
                .toList(),
            onChanged: (next) => setState(() => unitId = next),
          ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            expires == null ? 'Chưa đặt hạn dùng' : 'Ngày đã nhập: $expires',
          ),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final date = await showDatePicker(
              context: formContext,
              initialDate: expires == null
                  ? DateTime.now()
                  : kitchenDate(expires!),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (formContext.mounted && date != null) {
              setState(() => expires = dateKey(date));
            }
          },
        ),
        if (expires != null)
          TextButton(
            onPressed: () => setState(() => expires = null),
            child: const Text('Bỏ hạn dùng'),
          ),
        const Text(
          'Ngày do bạn nhập để theo dõi, không phải kết luận thực phẩm còn an toàn.',
        ),
      ],
      value: () {
        if (ingredient == null) {
          throw const FormatException('Chọn nguyên liệu trong danh mục.');
        }
        final quantity = amount.text.trim().isEmpty
            ? null
            : double.tryParse(amount.text.replaceAll(',', '.'));
        if (amount.text.trim().isNotEmpty && quantity == null) {
          throw const FormatException('Nhập số lượng hợp lệ.');
        }
        final lot = PantryLot(
          id: id,
          ingredientId: ingredient!.id,
          name: ingredient!.name,
          amount: quantity,
          unitId: quantity == null ? null : unitId,
          expiresOn: expires,
        );
        lot.toJson();
        return lot;
      },
      save: cubit.save,
    );
    amount.dispose();
  }

  Future<void> _consume(BuildContext context, PantryLot lot) async {
    final cubit = _cubit(context);
    final amount = TextEditingController();
    await showKitchenEntryForm<double>(
      context,
      title: 'Đã sử dụng ${lot.name}',
      fields: (_, _) => [
        kitchenInput(amount, 'Lượng đã dùng', number: true, maxLength: 12),
      ],
      value: () {
        final value = double.tryParse(amount.text.replaceAll(',', '.'));
        if (value == null || !value.isFinite || value <= 0) {
          throw const FormatException('Nhập lượng dùng lớn hơn 0.');
        }
        return value;
      },
      save: (value) => cubit.consume(lot.id, value),
    );
    amount.dispose();
  }

  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Nguyên liệu & hạn dùng',
    onBack: () => context.canPop() ? context.pop() : context.go('/fridge'),
    child: KitchenListBody<PantryLot>(
      children: (context, state) {
        final cubit = _cubit(context);
        return [
          AppButton(
            text: 'Thêm lô nguyên liệu',
            icon: Icons.add,
            onPressed: state.busy ? null : () => _edit(context),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.busy ? null : cubit.importSelected,
            child: const Text('Nhập các nguyên liệu đang chọn trong Tủ lạnh'),
          ),
          const Text(
            'Mỗi lô giữ lượng và ngày riêng. Các nguyên liệu chỉ đánh dấu đang có vẫn được giữ nguyên.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: PantryFilter.values
                .map(
                  (filter) => AppChoiceChip(
                    label: switch (filter) {
                      PantryFilter.all => 'Tất cả',
                      PantryFilter.soon => 'Sắp hết hạn',
                      PantryFilter.expired => 'Quá ngày đã nhập',
                    },
                    selected: cubit.filter == filter,
                    onSelected: (_) => cubit.select(filter),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (cubit.visible.isEmpty)
            const Text(
              'Chưa có lô phù hợp. Thêm nguyên liệu để theo dõi lượng và hạn dùng.',
            ),
          for (final lot in cubit.visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text(lot.name),
                      subtitle: Text(
                        '${lot.amount == null ? 'Chưa biết số lượng' : '${lot.amount} ${cubit.catalog?.unitsById[lot.unitId]?.label ?? lot.unitId}'}\n${lot.expiresOn == null ? 'Chưa đặt hạn dùng' : '${lot.isExpired(DateTime.now())
                                  ? 'Quá ngày đã nhập'
                                  : lot.isSoon(DateTime.now())
                                  ? 'Sắp đến hạn'
                                  : 'Hạn dùng'}: ${lot.expiresOn}'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        enabled: !state.busy,
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await _edit(context, initial: lot);
                          } else if (action == 'consume') {
                            await _consume(context, lot);
                          } else if (await kitchenConfirmDelete(context)) {
                            await cubit.remove(lot.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Sửa lô'),
                          ),
                          if (lot.amount != null && lot.amount! > 0)
                            const PopupMenuItem(
                              value: 'consume',
                              child: Text('Ghi lượng đã dùng'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa lô'),
                          ),
                        ],
                      ),
                    ),
                    if ((lot.amount == null || lot.amount! > 0) &&
                        !lot.isExpired(DateTime.now()))
                      TextButton(
                        onPressed: () => context.push(
                          '/recipes/search?q=${Uri.encodeQueryComponent(lot.name)}',
                        ),
                        child: Text('Tìm món dùng ${lot.name}'),
                      ),
                  ],
                ),
              ),
            ),
        ];
      },
    ),
  );
}
