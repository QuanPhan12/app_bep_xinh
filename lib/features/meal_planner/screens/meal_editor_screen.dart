import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/recipe_picker.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';
import '../cubits/meal_editor_cubit.dart';

class MealEditorScreen extends StatelessWidget {
  final String? editId, copyId, day;
  final MealSlot? slot;
  const MealEditorScreen({
    super.key,
    this.editId,
    this.copyId,
    this.day,
    this.slot,
  });
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MealEditorCubit(
      KitchenScope.of(context),
      editId: editId,
      copyId: copyId,
    )..load(),
    child: _EditorForm(
      day: day,
      slot: slot,
      editing: editId != null,
      copying: copyId != null,
    ),
  );
}

class _EditorForm extends StatefulWidget {
  final String? day;
  final MealSlot? slot;
  final bool editing, copying;
  const _EditorForm({
    this.day,
    this.slot,
    required this.editing,
    required this.copying,
  });
  @override
  State<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends State<_EditorForm> {
  final _name = TextEditingController(),
      _servings = TextEditingController(text: '2');
  late String _day = _initialDay();
  String _initialDay() {
    try {
      final date = kitchenDate(widget.day ?? dateKey(DateTime.now()));
      return date.year >= 2020 && date.year < 2100
          ? dateKey(date)
          : dateKey(DateTime.now());
    } catch (_) {
      return dateKey(DateTime.now());
    }
  }

  late MealSlot _slot = widget.slot ?? MealSlot.dinner;
  bool _initialized = false;
  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RecipeDiscoveryTheme(
    child: BlocConsumer<MealEditorCubit, MealEditorState>(
      listener: (context, state) {
        if (state.error != null) AppMessenger.showError(context, state.error!);
      },
      builder: (context, state) {
        final cubit = context.read<MealEditorCubit>();
        if (!state.loading && !_initialized) {
          _initialized = true;
          final initial = state.initial;
          if (initial != null) {
            _name.text = initial.name;
            _servings.text = '${initial.servings}';
            if (!widget.copying) {
              _day = initial.day;
              _slot = initial.slot;
            }
          }
        }
        return KitchenPage(
          title: widget.editing ? 'Sửa bữa ăn' : 'Lên bữa ăn',
          onBack: () => context.canPop()
              ? context.pop()
              : context.go('/kitchen/meal-plan'),
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.locked
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bữa này đã bắt đầu nấu. Tạo một bữa mới để thay đổi món hoặc khẩu phần.',
                        ),
                        TextButton(
                          onPressed: () => context.pushReplacement(
                            '/kitchen/meal-plan/new?copy=${cubit.id}',
                          ),
                          child: const Text('Dùng lại bữa này'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          TextField(
                            controller: _name,
                            enabled: !state.busy,
                            maxLength: 80,
                            decoration: const InputDecoration(
                              labelText: 'Tên bữa ăn',
                              hintText: 'Ví dụ: Bữa tối gia đình',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Thông tin bữa',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_day),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: state.busy
                                ? null
                                : () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: kitchenDate(_day),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (mounted && date != null) {
                                      setState(() => _day = dateKey(date));
                                    }
                                  },
                          ),
                          DropdownButtonFormField<MealSlot>(
                            initialValue: _slot,
                            decoration: const InputDecoration(
                              labelText: 'Bữa',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            items: [
                              for (final slot in MealSlot.values)
                                DropdownMenuItem(
                                  value: slot,
                                  child: Text(slot.label),
                                ),
                            ],
                            onChanged: state.busy
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _slot = value);
                                    }
                                  },
                          ),
                          TextField(
                            controller: _servings,
                            enabled: !state.busy,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            decoration: const InputDecoration(
                              labelText: 'Số người ăn chung cho cả bữa',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Các món trong bữa · ${state.dishes.length}/6',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              TextButton.icon(
                                onPressed:
                                    state.busy || state.dishes.length >= 6
                                    ? null
                                    : () async {
                                        final recipe =
                                            await showKitchenRecipePicker(
                                              context,
                                            );
                                        if (recipe != null && !cubit.isClosed) {
                                          cubit.add(
                                            RecipeRef.fromRecipe(recipe),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm món'),
                              ),
                            ],
                          ),
                          if (state.dishes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Chọn các món bạn muốn nấu cùng nhau.',
                              ),
                            ),
                          for (var i = 0; i < state.dishes.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          state.dishes[i].recipe.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      if (i > 0)
                                        IconButton(
                                          tooltip: 'Đưa lên',
                                          onPressed: state.busy
                                              ? null
                                              : () => cubit.move(i, -1),
                                          icon: const Icon(
                                            Icons.arrow_upward,
                                            size: 18,
                                          ),
                                        ),
                                      IconButton(
                                        tooltip: 'Bỏ món',
                                        onPressed: state.busy
                                            ? null
                                            : () => cubit.remove(i),
                                        icon: const Icon(Icons.close, size: 20),
                                      ),
                                    ],
                                  ),
                                  DropdownButton<MealDishRole>(
                                    value: state.dishes[i].role,
                                    underline: const SizedBox.shrink(),
                                    isExpanded: true,
                                    items: [
                                      for (final role in MealDishRole.values)
                                        DropdownMenuItem(
                                          value: role,
                                          child: Text(role.label),
                                        ),
                                    ],
                                    onChanged: state.busy
                                        ? null
                                        : (role) {
                                            if (role != null) {
                                              cubit.role(i, role);
                                            }
                                          },
                                  ),
                                ],
                              ),
                            ),
                          if (state.suggestions.isNotEmpty &&
                              state.dishes.length < 6) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Gợi ý từ tủ lạnh',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Text(
                              'Dựa trên nguyên liệu đã chọn; kiểm tra lại lượng trước khi nấu.',
                            ),
                            for (final recipe in state.suggestions.where(
                              (r) =>
                                  !state.dishes.any((d) => d.recipe.id == r.id),
                            ))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(recipe.title),
                                subtitle: Text('${recipe.minutes} phút'),
                                trailing: const Icon(Icons.add),
                                onTap: state.busy
                                    ? null
                                    : () => cubit.addSuggestion(recipe.id),
                              ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final saved = await cubit.save(
                                    name: _name.text.trim(),
                                    day: _day,
                                    slot: _slot,
                                    servings: _servings.text,
                                  );
                                  if (context.mounted && saved) {
                                    context.pushReplacement(
                                      '/kitchen/meal-plan/${cubit.id}',
                                    );
                                  }
                                },
                          child: Text(state.busy ? 'Đang lưu…' : 'Lưu bữa ăn'),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    ),
  );
}
