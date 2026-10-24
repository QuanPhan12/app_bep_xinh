import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';

import '../cubits/ingredient_picker/ingredient_picker_cubit.dart';
import '../validation/recipe_editor_validation.dart';

import 'package:app_bep_xinh/core/widgets/app_search_bar.dart';

class RecipeIngredientSearch extends StatelessWidget {
  const RecipeIngredientSearch({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<IngredientPickerCubit, IngredientPickerState>(
    builder: (context, state) {
      final cubit = context.read<IngredientPickerCubit>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchBar(
            fieldKey: const ValueKey('ingredient_search'),
            initialValue: state.query,
            hintText: 'Tìm nguyên liệu',
            maxLength: RecipeEditorLimits.ingredientNameLength,
            onChanged: cubit.search,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.searching
                ? const SkeletonListRows()
                : state.failure != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.failure!, style: AppTextStyles.bodyMedium),
                        TextButton(
                          onPressed: context.onAppTap(
                            () => cubit.search(state.query),
                            actionName: 'ingredient_retry_search',
                            allowConcurrent: true,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    key: const ValueKey('ingredient_results'),
                    children: [
                      if (state.results.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Chưa tìm thấy nguyên liệu phù hợp.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      for (final item in state.results)
                        ListTile(
                          key: ValueKey('ingredient_option_${item.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.name,
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Text(
                            item.group,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: context.onAppTap(
                            () => cubit.choose(item),
                            actionName: 'ingredient_select_${item.id}',
                            allowConcurrent: true,
                          ),
                        ),
                      if (state.query.trim().isNotEmpty)
                        ListTile(
                          key: const ValueKey('ingredient_custom'),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.add,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Dùng “${state.query.trim()}”',
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Text(
                            'Thêm nguyên liệu khác',
                            style: AppTextStyles.bodySmall,
                          ),
                          onTap: context.onAppTap(
                            cubit.chooseCustom,
                            actionName: 'ingredient_custom',
                            allowConcurrent: true,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}
