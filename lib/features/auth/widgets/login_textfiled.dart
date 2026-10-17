import 'package:flutter/material.dart';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/dimensions.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String label;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onSuffixIconTap;
  final double? height;
  final String? errorText;

  const LoginTextField({
    super.key,
    this.controller,
    this.onChanged,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onSuffixIconTap,
    this.height,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;
    final effectiveHeight = height ?? size.inputHeight;
    // Tính verticalPadding động để khung viền (border) và màu nền phình to đúng bằng effectiveHeight
    final verticalPadding = ((effectiveHeight - 22) / 2).clamp(10.0, 45.0);

    return SizedBox(
      height: effectiveHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          isDense: true,
          errorText: errorText,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: verticalPadding,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: size.iconMedium,
          ),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixIconTap,
                  icon: Icon(
                    suffixIcon,
                    size: size.iconMedium,
                    color: AppColors.textTertiary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
