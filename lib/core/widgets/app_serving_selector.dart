import 'package:flutter/cupertino.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import 'app_tap.dart';

/// Ô khẩu phần tách từ form Đăng món, dùng chung khi nhập/xem công thức.
class AppServingSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
  const AppServingSelector({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 1,
    this.max = 50,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text('Khẩu phần (người)', style: AppTextStyles.labelMedium),
      ),
      _ServingButton(
        label: 'Giảm khẩu phần',
        icon: CupertinoIcons.minus,
        onTap: onChanged == null || value <= min
            ? null
            : () => onChanged!(value - 1),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text('$value', style: AppTextStyles.labelMedium),
      ),
      _ServingButton(
        label: 'Tăng khẩu phần',
        icon: CupertinoIcons.plus,
        onTap: onChanged == null || value >= max
            ? null
            : () => onChanged!(value + 1),
      ),
    ],
  );
}

class _ServingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ServingButton({required this.label, required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AppTap(
      actionName: 'recipe_servings_$label',
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.textMuted : AppColors.primary,
        ),
      ),
    ),
  );
}
