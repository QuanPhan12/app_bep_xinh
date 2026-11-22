import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/kitchen_entry_form.dart';
import '../../kitchen/widgets/recipe_picker.dart';

Future<bool> showCookingLogEditor(
  BuildContext context, {
  CookingLog? initial,
  RecipeRef? recipe,
  String? sessionId,
  int servings = 2,
}) async {
  final cubit = KitchenListCubit<CookingLog>(KitchenScope.of(context).journal);
  var selected = initial?.recipe ?? recipe;
  var day = initial?.day ?? dateKey(DateTime.now());
  final id = initial?.id ?? sessionId ?? kitchenId();
  final amount = TextEditingController(
    text: '${initial?.servings ?? servings}',
  );
  final note = TextEditingController(text: initial?.note ?? '');
  final result = await showKitchenEntryForm<CookingLog>(
    context,
    title: 'Ghi lại lần nấu',
    fields: (formContext, setState) => [
      ListTile(
        title: Text(selected?.title ?? 'Chọn món đã nấu'),
        trailing: const Icon(Icons.restaurant),
        onTap: initial != null || recipe != null
            ? null
            : () async {
                final next = await showKitchenRecipePicker(context);
                if (formContext.mounted && next != null) {
                  setState(() => selected = RecipeRef.fromRecipe(next));
                }
              },
      ),
      ListTile(
        title: Text('Ngày nấu: $day'),
        trailing: const Icon(Icons.calendar_month),
        onTap: () async {
          final date = await showDatePicker(
            context: formContext,
            initialDate: kitchenDate(day),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (formContext.mounted && date != null) {
            setState(() => day = dateKey(date));
          }
        },
      ),
      kitchenInput(amount, 'Số người ăn', number: true, maxLength: 2),
      kitchenInput(
        note,
        'Ghi chú riêng',
        maxLength: 1000,
        lines: 4,
        required: false,
      ),
    ],
    value: () {
      if (selected == null) throw const FormatException('Chọn món đã nấu.');
      return CookingLog(
        id: id,
        recipe: selected!,
        day: day,
        servings: kitchenInt(int.tryParse(amount.text), 1, 50),
        note: kitchenText(note.text, 1000, empty: true),
      );
    },
    save: cubit.save,
  );
  amount.dispose();
  note.dispose();
  await cubit.close();
  return result != null;
}

class CookingJournalScreen extends StatelessWidget {
  const CookingJournalScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        KitchenListCubit<CookingLog>(KitchenScope.of(context).journal)..load(),
    child: const _JournalPage(),
  );
}

class _JournalPage extends StatelessWidget {
  const _JournalPage();
  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Nhật ký nấu ăn',
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
    child: KitchenListBody<CookingLog>(
      children: (context, state) {
        final entries = [...state.items]
          ..sort((a, b) => b.day.compareTo(a.day));
        return [
          const Text(
            'Ghi chú chỉ bạn đọc được. Mỗi lần nấu có một bản ghi riêng.',
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Ghi lần nấu',
            icon: Icons.add,
            onPressed: state.busy ? null : () => showCookingLogEditor(context),
          ),
          const SizedBox(height: 16),
          Text(
            state.items.length == 500
                ? '500 lần nấu gần nhất'
                : '${state.items.length} lần nấu',
          ),
          const SizedBox(height: 16),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.recipe.title),
                      subtitle: Text('${entry.day} · ${entry.servings} người'),
                      onTap: () => context.push(
                        '/recipe/${Uri.encodeComponent(entry.recipe.id)}',
                      ),
                      trailing: PopupMenuButton<String>(
                        enabled: !state.busy,
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await showCookingLogEditor(context, initial: entry);
                          } else if (await kitchenConfirmDelete(context)) {
                            if (context.mounted) {
                              await context
                                  .read<KitchenListCubit<CookingLog>>()
                                  .remove(entry.id);
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Sửa ghi chú'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa lần nấu'),
                          ),
                        ],
                      ),
                    ),
                    if (entry.note.isNotEmpty) Text(entry.note),
                  ],
                ),
              ),
            ),
          if (entries.isEmpty)
            const Text(
              'Chưa có lần nấu nào. Bạn cũng có thể lưu nhật ký sau khi hoàn tất một món.',
            ),
        ];
      },
    ),
  );
}
