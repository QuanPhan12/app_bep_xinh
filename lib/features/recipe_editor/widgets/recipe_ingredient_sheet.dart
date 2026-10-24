import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/ingredient_picker/ingredient_picker_cubit.dart';
import '../models/recipe_draft.dart';
import 'recipe_ingredient_amount_fields.dart';
import 'recipe_ingredient_search.dart';

Future<RecipeIngredientDraft?> showRecipeIngredientSheet(
  BuildContext context, {
  RecipeIngredientDraft? initial,
}) {
  final service = context.read<IngredientCatalogService>();
  return showModalBottomSheet<RecipeIngredientDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
    builder: (context) {
      final media = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: (media.size.height * .82 - media.viewInsets.bottom).clamp(
            180,
            media.size.height * .82,
          ),
          child: BlocProvider(
            create: (_) =>
                IngredientPickerCubit(service: service, initial: initial)
                  ..load(),
            child: _IngredientSheet(editing: initial != null),
          ),
        ),
      );
    },
  );
}

class _IngredientSheet extends StatelessWidget {
  final bool editing;
  const _IngredientSheet({required this.editing});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<IngredientPickerCubit, IngredientPickerState>(
        builder: (context, state) {
          final cubit = context.read<IngredientPickerCubit>();
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          editing ? 'Sửa nguyên liệu' : 'Thêm nguyên liệu',
                          style: AppTextStyles.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: context.onAppTap(
                          () => Navigator.of(context).pop(),
                          actionName: 'ingredient_close',
                          allowConcurrent: true,
                        ),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        state.loading ||
                            (state.catalog == null && state.failure != null)
                        ? AppLoadState(
                            skeleton: const SkeletonListRows(),
                            isLoading: state.loading,
                            message: state.failure,
                            onRetry: cubit.load,
                          )
                        : state.hasSelection
                        ? RecipeIngredientAmountFields(
                            key: ValueKey(state.name),
                          )
                        : const RecipeIngredientSearch(),
                  ),
                  if (state.hasSelection) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      key: const ValueKey('ingredient_confirm'),
                      text: editing ? 'Lưu thay đổi' : 'Thêm nguyên liệu',
                      actionName: 'ingredient_confirm',
                      allowConcurrent: true,
                      onPressed: () {
                        final result = cubit.confirm();
                        if (result != null) Navigator.of(context).pop(result);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
}
