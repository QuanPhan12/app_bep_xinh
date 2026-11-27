import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/search_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_tabs.dart';
import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/cubits/kitchen_list_cubit.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/recipe_picker.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';
import '../models/nutrition.dart';
import '../cubits/nutrition_cubit.dart';
import '../services/nutrition_repository.dart';
import '../services/nutrition_photo_picker.dart';

class NutritionScreen extends StatelessWidget {
  final String? recipeId, mealId;
  final int? servings;
  const NutritionScreen({super.key, this.recipeId, this.mealId, this.servings});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => NutritionCubit(
      repository: context.read<NutritionRepository>(),
      photos: context.read<NutritionPhotoPicker>(),
      kitchen: KitchenScope.of(context),
    )..load(recipeId: recipeId, mealId: mealId, servings: servings),
    child: const RecipeDiscoveryTheme(child: _NutritionPage()),
  );
}

class _NutritionPage extends StatefulWidget {
  const _NutritionPage();
  @override
  State<_NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<_NutritionPage> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context, NutritionCubit cubit) async {
    final saved = await showAppAdaptiveSheet<bool>(
      context: context,
      builder: (_) =>
          RecipeDiscoveryTheme(child: _NutritionSaveSheet(cubit: cubit)),
    );
    if (saved == true && context.mounted) {
      AppMessenger.showSuccess(context, 'Đã lưu vào nhật ký ăn uống.');
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<NutritionCubit, NutritionState>(
    listenWhen: (previous, next) =>
        next.error != null || (!previous.ready && next.ready),
    listener: (context, state) {
      if (state.error != null) AppMessenger.showError(context, state.error!);
      if (state.ready) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        });
      }
    },
    builder: (context, state) {
      final cubit = context.read<NutritionCubit>();
      final editing = !state.busy && !state.saved;
      final hasInput =
          state.photo != null || state.description.trim().isNotEmpty;
      final hasLines = state.lines.isNotEmpty;
      final complete = hasLines && state.lines.every(state.catalog!.valid);
      return KitchenPage(
        title: 'Ước tính calo',
        onBack: () => context.canPop() ? context.pop() : context.go('/kitchen'),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.catalog == null
            ? Center(
                child: TextButton(
                  onPressed: () => cubit.load(),
                  child: const Text('Tải lại dữ liệu dinh dưỡng'),
                ),
              )
            : Column(
                children: [
                  AppTabs(
                    labels: const ['Ước tính', 'Nhật ký ăn'],
                    selectedIndex: state.tab,
                    onSelected: cubit.tab,
                  ),
                  Expanded(
                    child: state.tab == 1
                        ? _NutritionHistory(
                            repository: cubit.repository,
                            catalog: state.catalog!,
                          )
                        : Theme(
                            data: _formTheme(context),
                            child: ListView(
                              controller: _scroll,
                              padding: const EdgeInsets.all(20),
                              children: [
                                if (!hasLines) ...[
                                  if (state.photo != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        state.photo!,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        semanticLabel: 'Ảnh bữa ăn bạn chọn',
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: editing
                                            ? cubit.clearPhoto
                                            : null,
                                        child: const Text('Bỏ ảnh'),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Bữa này có gì?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Thêm ảnh hoặc mô tả món ăn để bắt đầu.',
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      TextButton.icon(
                                        onPressed: editing
                                            ? () => cubit.choosePhoto(
                                                camera: true,
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.camera_alt_outlined,
                                        ),
                                        label: const Text('Chụp ảnh'),
                                      ),
                                      TextButton.icon(
                                        onPressed: editing
                                            ? () => cubit.choosePhoto()
                                            : null,
                                        icon: const Icon(Icons.photo_outlined),
                                        label: const Text('Chọn ảnh'),
                                      ),
                                      TextButton.icon(
                                        onPressed: editing
                                            ? () async {
                                                final recipe =
                                                    await showKitchenRecipePicker(
                                                      context,
                                                    );
                                                if (recipe != null &&
                                                    !cubit.isClosed) {
                                                  cubit.useRecipes(
                                                    [recipe],
                                                    title: recipe.title,
                                                    servings: recipe.servings,
                                                  );
                                                }
                                              }
                                            : null,
                                        icon: const Icon(Icons.restaurant_menu),
                                        label: const Text('Chọn công thức'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _NutritionTextField(
                                    value: state.description,
                                    label: 'Món ăn của bạn',
                                    hint: 'Ví dụ: cơm, trứng chiên và rau luộc',
                                    maxLength: 2000,
                                    maxLines: 3,
                                    enabled: editing,
                                    onChanged: cubit.description,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'AI dùng ảnh/mô tả để nhận diện và bổ sung tên nguyên liệu mới vào danh mục chung.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: editing
                                        ? () async {
                                            final food = await _chooseFood(
                                              context,
                                              state.catalog!,
                                            );
                                            if (food != null &&
                                                !cubit.isClosed) {
                                              cubit.addNamedIngredient(food);
                                            }
                                          }
                                        : null,
                                    child: const Text('Tự nhập nguyên liệu'),
                                  ),
                                ] else ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          state.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: editing ? cubit.reset : null,
                                        child: const Text('Đổi bữa'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    key: ValueKey('portions_${state.servings}'),
                                    initialValue: state.servings,
                                    menuMaxHeight: 280,
                                    decoration: const InputDecoration(
                                      labelText: 'Khẩu phần',
                                    ),
                                    items: [
                                      for (var i = 1; i <= 50; i++)
                                        DropdownMenuItem(
                                          value: i,
                                          child: Text('$i phần'),
                                        ),
                                    ],
                                    onChanged: editing
                                        ? (v) {
                                            if (v != null) {
                                              cubit.metadata(servings: v);
                                            }
                                          }
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  if (state.ready) ...[
                                    _NutritionResult(
                                      total: state.total!,
                                      servings: state.servings,
                                    ),
                                    const SizedBox(height: 28),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Nguyên liệu',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                      ),
                                      if (!complete && !state.saved)
                                        TextButton.icon(
                                          onPressed: editing
                                              ? cubit.recognize
                                              : null,
                                          icon: const Icon(
                                            Icons.auto_awesome_outlined,
                                          ),
                                          label: const Text('AI gợi ý'),
                                        ),
                                      IconButton(
                                        tooltip: 'Thêm thực phẩm',
                                        onPressed:
                                            editing && state.lines.length < 180
                                            ? () async {
                                                final food = await _chooseFood(
                                                  context,
                                                  state.catalog!,
                                                );
                                                if (food != null &&
                                                    !cubit.isClosed) {
                                                  cubit.addNamedIngredient(
                                                    food,
                                                  );
                                                }
                                              }
                                            : null,
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                  if (!state.ready)
                                    Text(
                                      complete
                                          ? 'Kiểm tra lượng nguyên liệu rồi bấm Tính calo.'
                                          : 'Chọn loại thực phẩm và bổ sung gram còn thiếu.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  for (var i = 0; i < state.lines.length; i++)
                                    _NutritionLineEditor(
                                      key: ValueKey(state.lines[i].id),
                                      line: state.lines[i],
                                      catalog: state.catalog!,
                                      enabled: editing,
                                      onFood: () async {
                                        final food = await _chooseFood(
                                          context,
                                          state.catalog!,
                                          query: state.lines[i].name,
                                          allowUnmapped: false,
                                        );
                                        if (food != null && !cubit.isClosed) {
                                          cubit.line(i, foodId: food.foodId);
                                        }
                                      },
                                      onGrams: (v) {
                                        final amount = int.tryParse(v);
                                        cubit.line(
                                          i,
                                          grams: amount?.toDouble(),
                                          clearGrams: amount == null,
                                        );
                                      },
                                      onRemove: () => cubit.remove(i),
                                    ),
                                  if (!complete && !state.saved) ...[
                                    const Text(
                                      'Nguyên liệu được gửi tới AI khi dùng gợi ý.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Kết quả là ước tính từ dữ liệu USDA.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  if (state.tab == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.busy
                              ? null
                              : state.saved
                              ? cubit.reset
                              : !hasLines
                              ? (hasInput ? cubit.recognize : null)
                              : state.ready
                              ? () => _save(context, cubit)
                              : complete
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  cubit.confirmAll();
                                }
                              : null,
                          child: Text(
                            state.busy
                                ? 'Đang xử lý…'
                                : state.saved
                                ? 'Ước tính bữa khác'
                                : !hasLines
                                ? 'Ước tính calo'
                                : state.ready
                                ? 'Lưu bữa ăn'
                                : 'Tính calo',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );
}

ThemeData _formTheme(BuildContext context) => Theme.of(context).copyWith(
  inputDecorationTheme: const InputDecorationTheme(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    filled: false,
  ),
);

class _NutritionSaveSheet extends StatelessWidget {
  final NutritionCubit cubit;
  const _NutritionSaveSheet({required this.cubit});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<NutritionCubit, NutritionState>(
    bloc: cubit,
    builder: (context, state) => Theme(
      data: _formTheme(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final height = (available - MediaQuery.viewInsetsOf(context).bottom)
              .clamp(0.0, 560.0);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lưu bữa ăn',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: state.busy
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          _NutritionTextField(
                            value: state.title,
                            label: 'Tên bữa',
                            maxLength: 80,
                            enabled: !state.busy,
                            onChanged: (v) => cubit.metadata(title: v),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(state.day),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: state.busy
                                ? null
                                : () async {
                                    final day = await showDatePicker(
                                      context: context,
                                      initialDate: kitchenDate(state.day),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (day != null && !cubit.isClosed) {
                                      cubit.metadata(day: dateKey(day));
                                    }
                                  },
                          ),
                          DropdownButtonFormField<MealSlot>(
                            key: ValueKey(state.slot),
                            initialValue: state.slot,
                            decoration: const InputDecoration(labelText: 'Bữa'),
                            items: [
                              for (final slot in MealSlot.values)
                                DropdownMenuItem(
                                  value: slot,
                                  child: Text(slot.label),
                                ),
                            ],
                            onChanged: state.busy
                                ? null
                                : (slot) {
                                    if (slot != null) {
                                      cubit.metadata(slot: slot);
                                    }
                                  },
                          ),
                          DropdownButtonFormField<int>(
                            key: ValueKey(state.consumed),
                            initialValue: state.consumed,
                            menuMaxHeight: 240,
                            decoration: const InputDecoration(
                              labelText: 'Phần bạn đã ăn',
                            ),
                            items: [
                              for (var i = 1; i <= state.servings; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text('$i phần'),
                                ),
                            ],
                            onChanged: state.busy
                                ? null
                                : (value) {
                                    if (value != null) {
                                      cubit.metadata(consumed: value);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${(state.total!.kcal * state.consumed / state.servings).round()} kcal sẽ được ghi vào nhật ký.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.busy
                            ? null
                            : () async {
                                if (await cubit.save() && context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              },
                        child: Text(
                          state.busy ? 'Đang lưu…' : 'Đã ăn · Lưu nhật ký',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _NutritionTextField extends StatefulWidget {
  final String value, label;
  final String? hint;
  final int maxLength, maxLines;
  final bool enabled;
  final ValueChanged<String> onChanged;
  const _NutritionTextField({
    required this.value,
    required this.label,
    this.hint,
    required this.maxLength,
    this.maxLines = 1,
    required this.enabled,
    required this.onChanged,
  });
  @override
  State<_NutritionTextField> createState() => _NutritionTextFieldState();
}

class _NutritionTextFieldState extends State<_NutritionTextField> {
  late final _controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(covariant _NutritionTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    enabled: widget.enabled,
    maxLength: widget.maxLength,
    maxLines: widget.maxLines,
    minLines: 1,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      counterText: '',
    ),
  );
}

class _NutritionResult extends StatelessWidget {
  final NutritionTotals total;
  final int servings;
  const _NutritionResult({required this.total, required this.servings});
  @override
  Widget build(BuildContext context) {
    final per = total.scaled(1 / servings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ước tính mỗi phần',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          '${per.kcal.round()} kcal',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (servings > 1) Text('Cả bữa: ${total.kcal.round()} kcal'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 28,
          runSpacing: 12,
          children: [
            for (final entry in [
              ('Đạm', per.protein),
              ('Tinh bột', per.carbs),
              ('Chất béo', per.fat),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.$2.round()} g',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(entry.$1),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _NutritionLineEditor extends StatefulWidget {
  final NutritionLine line;
  final NutritionCatalog catalog;
  final bool enabled;
  final VoidCallback onFood, onRemove;
  final ValueChanged<String> onGrams;
  const _NutritionLineEditor({
    super.key,
    required this.line,
    required this.catalog,
    required this.enabled,
    required this.onFood,
    required this.onRemove,
    required this.onGrams,
  });
  @override
  State<_NutritionLineEditor> createState() => _NutritionLineEditorState();
}

class _NutritionLineEditorState extends State<_NutritionLineEditor> {
  late final _grams = TextEditingController(
    text: widget.line.grams?.round().toString() ?? '',
  );
  @override
  void didUpdateWidget(covariant _NutritionLineEditor old) {
    super.didUpdateWidget(old);
    if (old.line.grams != widget.line.grams &&
        int.tryParse(_grams.text)?.toDouble() != widget.line.grams) {
      _grams.text = widget.line.grams?.round().toString() ?? '';
    }
  }

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.catalog.byId[widget.line.foodId];
    final name = InkWell(
      onTap: widget.enabled ? widget.onFood : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.line.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (food == null || food.name != widget.line.name)
              Text(
                food?.name ?? 'Chọn loại thực phẩm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
    final grams = TextField(
      key: ValueKey('grams_${widget.line.id}'),
      controller: _grams,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: 'Gram',
        suffixText: 'g',
        errorText:
            widget.line.grams != null &&
                (widget.line.grams! <= 0 || widget.line.grams! > 100000)
            ? '1–100000'
            : null,
      ),
      onChanged: widget.onGrams,
    );
    final menu = PopupMenuButton<String>(
      tooltip: 'Tùy chọn nguyên liệu',
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (value) {
        if (value == 'change') {
          widget.onFood();
        } else if (value == 'remove') {
          widget.onRemove();
        } else {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(widget.line.name),
              content: Text(
                [
                  if (widget.line.sourceQuantity != null)
                    'Theo công thức: ${widget.line.sourceQuantity}',
                  if (food != null)
                    '${food.name}\n${food.description}\nUSDA ${food.id} · ${food.kcal.round()} kcal / 100 g',
                ].join('\n\n'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: widget.enabled,
          value: 'change',
          child: const Text('Đổi loại thực phẩm'),
        ),
        const PopupMenuItem(value: 'details', child: Text('Chi tiết')),
        PopupMenuItem(
          enabled: widget.enabled,
          value: 'remove',
          child: const Text('Bỏ nguyên liệu'),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: stack
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: name),
                        menu,
                      ],
                    ),
                    SizedBox(width: 160, child: grams),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    SizedBox(width: 92, child: grams),
                    menu,
                  ],
                ),
        );
      },
    );
  }
}

Future<NutritionLine?> _chooseFood(
  BuildContext context,
  NutritionCatalog catalog, {
  String query = '',
  bool allowUnmapped = true,
}) => showAppAdaptiveSheet<NutritionLine>(
  context: context,
  builder: (_) => _FoodChooser(
    catalog: catalog,
    query: query,
    allowUnmapped: allowUnmapped,
  ),
);

class _FoodChooser extends StatefulWidget {
  final NutritionCatalog catalog;
  final String query;
  final bool allowUnmapped;
  const _FoodChooser({
    required this.catalog,
    required this.query,
    required this.allowUnmapped,
  });
  @override
  State<_FoodChooser> createState() => _FoodChooserState();
}

class _FoodChooserState extends State<_FoodChooser> {
  late String _query = widget.query;
  late final _keys = {
    for (final f in widget.catalog.foods)
      f.id: searchKey('${f.id} ${f.name} ${f.description}'),
  };
  @override
  Widget build(BuildContext context) {
    final terms = searchKey(_query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final foods = terms.isEmpty
        ? widget.catalog.aiFoods
        : widget.catalog.foods
              .where((f) => terms.every(_keys[f.id]!.contains))
              .take(80)
              .toList();
    final knownNames = widget.catalog.foods
        .map((f) => searchKey(f.name))
        .toSet();
    final unmapped = widget.allowUnmapped
        ? widget.catalog.ingredientNames
              .where(
                (name) =>
                    !knownNames.contains(searchKey(name)) &&
                    terms.every(searchKey(name).contains),
              )
              .toList()
        : <String>[];
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = MediaQuery.viewInsetsOf(context).bottom;
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SizedBox(
            height: (available - inset).clamp(0.0, 560.0),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Chọn loại thực phẩm')),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: _query,
                    decoration: const InputDecoration(
                      labelText: 'Tìm thực phẩm',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  if (foods.isEmpty && unmapped.isEmpty)
                    const Text(
                      'Chưa có kết quả. Thử tên ngắn hơn hoặc tên tiếng Anh.',
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: unmapped.length + foods.length,
                      itemBuilder: (context, index) {
                        if (index < unmapped.length) {
                          final name = unmapped[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name),
                            subtitle: const Text('Cần chọn dữ liệu dinh dưỡng'),
                            onTap: () => Navigator.pop(
                              context,
                              NutritionLine(id: kitchenId(), name: name),
                            ),
                          );
                        }
                        final food = foods[index - unmapped.length];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(food.name),
                          subtitle: Text('${food.kcal.round()} kcal / 100 g'),
                          onTap: () => Navigator.pop(
                            context,
                            NutritionLine(
                              id: kitchenId(),
                              name: food.name,
                              foodId: food.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NutritionHistory extends StatelessWidget {
  final NutritionRepository repository;
  final NutritionCatalog catalog;
  const _NutritionHistory({required this.repository, required this.catalog});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => KitchenListCubit<NutritionEntry>(repository.journal)..load(),
    child: KitchenListBody<NutritionEntry>(
      children: (context, state) => [
        if (state.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Chưa có bữa ăn đã ghi nhận.'),
          ),
        for (final item
            in (state.items.toList()..sort((a, b) => b.day.compareTo(a.day))))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.title),
            subtitle: Text(
              '${item.day} · ${item.slot.label}\n${item.totals.kcal.round()} kcal · ${item.consumedServings} phần đã ăn',
            ),
            trailing: IconButton(
              tooltip: 'Xóa bản ghi',
              icon: const Icon(Icons.close),
              onPressed: state.busy
                  ? null
                  : () async {
                      if (await kitchenConfirmDelete(context) &&
                          context.mounted) {
                        await context
                            .read<KitchenListCubit<NutritionEntry>>()
                            .remove(item.id);
                      }
                    },
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(item.title),
                content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.totals.kcal.round()} kcal · Đạm ${item.totals.protein.round()} g · Tinh bột ${item.totals.carbs.round()} g · Béo ${item.totals.fat.round()} g',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Đã ăn ${item.consumedServings}/${item.servings} phần. Nguyên liệu bên dưới là của toàn bữa.',
                        ),
                        for (final line in item.lines)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${line.name}: ${line.grams!.round()} g · USDA ${line.foodId}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
