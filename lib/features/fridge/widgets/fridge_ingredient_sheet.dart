import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/widgets/app_adaptive_sheet.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import 'fridge_ingredient_picker.dart';

Future<void> showFridgeIngredientSheet(BuildContext context) async {
  final cubit = context.read<FridgeCubit>();
  cubit.searchIngredients('');
  await showAppAdaptiveSheet<void>(
    context: context,
    showDragHandle: false,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _FridgeIngredientSheet()),
  );
}

class _FridgeIngredientSheet extends StatelessWidget {
  const _FridgeIngredientSheet();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final height = (constraints.maxHeight - keyboard).clamp(0.0, 720.0);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          key: const ValueKey('fridge_ingredient_sheet'),
          height: height,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chọn nguyên liệu',
                              style: AppTextStyles.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng bảng nguyên liệu',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(PhosphorIconsRegular.x),
                          ),
                        ],
                      ),
                      BlocSelector<FridgeCubit, FridgeState, int>(
                        selector: (state) => state.selectedIds.length,
                        builder: (context, count) => Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  'Đã chọn $count nguyên liệu',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 12),
                              AppTextAction(
                                label: 'Xóa hết',
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                actionName: 'fridge_clear_all',
                                allowConcurrent: true,
                                onTap: context
                                    .read<FridgeCubit>()
                                    .clearIngredients,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const FridgeIngredientPicker(),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: BlocSelector<FridgeCubit, FridgeState, bool>(
                    selector: (state) => state.isSaving,
                    builder: (context, saving) => AppButton(
                      text: 'Xem gợi ý',
                      actionName: 'fridge_close_ingredients',
                      isLoading: saving,
                      allowConcurrent: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
