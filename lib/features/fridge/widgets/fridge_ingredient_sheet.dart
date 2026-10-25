import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import 'fridge_ingredient_picker.dart';

Future<void> showFridgeIngredientSheet(BuildContext context) async {
  final cubit = context.read<FridgeCubit>();
  cubit.searchIngredients('');
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    constraints: BoxConstraints(maxWidth: AppLayout.sheetWidth(context)),
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
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      BlocSelector<FridgeCubit, FridgeState, int>(
                        selector: (state) => state.selectedIds.length,
                        builder: (_, count) => Semantics(
                          liveRegion: true,
                          child: Text(
                            'Đã chọn $count nguyên liệu · Tự động lưu',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppFeatureTheme.muted,
                            ),
                          ),
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
