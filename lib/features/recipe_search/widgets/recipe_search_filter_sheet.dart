import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../../core/widgets/app_selection_controls.dart';
import '../../../sollume/shared/app_text_field.dart';
import '../../recipes/presentation/recipe_labels.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';
import '../../recipes/widgets/recipe_section.dart';
import '../cubits/recipe_search_filter_cubit.dart';
import '../models/recipe_search_request.dart';

Future<RecipeSearchRequest?> showRecipeSearchFilters(
  BuildContext context,
  RecipeSearchRequest request,
) => showAppAdaptiveSheet<RecipeSearchRequest>(
  context: context,
  builder: (_) => RecipeDiscoveryTheme(
    child: BlocProvider(
      create: (_) => RecipeSearchFilterCubit(request),
      child: const _FilterSheet(),
    ),
  ),
);

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeSearchFilterCubit, RecipeSearchRequest>(
        builder: (context, state) {
          final cubit = context.read<RecipeSearchFilterCubit>();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bộ lọc',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng bộ lọc',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(PhosphorIconsBold.x),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RecipeSection(
                            title: 'Tổng thời gian',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                AppChoiceChip(
                                  label: 'Bất kỳ',
                                  selected: state.maxMinutes == null,
                                  onSelected: (_) => cubit.selectMinutes(null),
                                ),
                                for (final minutes in [15, 30, 45, 60, 90, 120])
                                  AppChoiceChip(
                                    key: ValueKey('search_minutes_$minutes'),
                                    label: '≤ $minutes phút',
                                    selected: state.maxMinutes == minutes,
                                    onSelected: (_) =>
                                        cubit.selectMinutes(minutes),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          RecipeSection(
                            title: 'Độ khó',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                AppChoiceChip(
                                  label: 'Tất cả mức độ',
                                  selected: state.difficulty == null,
                                  onSelected: (_) =>
                                      cubit.selectDifficulty(null),
                                ),
                                for (final difficulty
                                    in RecipeDifficulty.values)
                                  AppChoiceChip(
                                    key: ValueKey(
                                      'search_difficulty_${difficulty.name}',
                                    ),
                                    label: difficulty.label,
                                    selected: state.difficulty == difficulty,
                                    onSelected: (_) =>
                                        cubit.selectDifficulty(difficulty),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const RecipeSection(
                            title: 'Nguyên liệu muốn tránh',
                            child: _ExcludedInput(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhập tên nguyên liệu, cách nhau bằng dấu phẩy.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: cubit.reset,
                          child: const Text('Đặt lại'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('search_apply_filters'),
                            onPressed: () =>
                                Navigator.of(context).pop(cubit.state),
                            child: const Text('Áp dụng'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _ExcludedInput extends StatefulWidget {
  const _ExcludedInput();
  @override
  State<_ExcludedInput> createState() => _ExcludedInputState();
}

class _ExcludedInputState extends State<_ExcludedInput> {
  late final _controller = TextEditingController(
    text: context.read<RecipeSearchFilterCubit>().state.excludedIngredients,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<RecipeSearchFilterCubit, RecipeSearchRequest>(
        listener: (context, state) {
          if (_controller.text != state.excludedIngredients) {
            _controller.value = TextEditingValue(
              text: state.excludedIngredients,
              selection: TextSelection.collapsed(
                offset: state.excludedIngredients.length,
              ),
            );
          }
        },
        child: AppTextField(
          key: const ValueKey('search_excluded_ingredients'),
          controller: _controller,
          hintText: 'Ví dụ: tôm, đậu phộng',
          showFocusedBorder: false,
          inputFormatters: [LengthLimitingTextInputFormatter(120)],
          onChanged: context.read<RecipeSearchFilterCubit>().changeExcluded,
        ),
      );
}
