import 'package:flutter/material.dart';

import '../../../sollume/shared/app_text_field.dart' as sollume;

class LoginTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final String label;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onSuffixIconTap;
  final double? height;
  final String? errorText;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  const LoginTextField({
    super.key,
    this.controller,
    this.initialValue = '',
    this.onChanged,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onSuffixIconTap,
    this.height,
    this.errorText,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => sollume.AppTextField(
    enabled: enabled,
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    hintText: label,
    onChanged: onChanged,
    validator: validator,
    autovalidateMode: validator == null
        ? AutovalidateMode.disabled
        : AutovalidateMode.onUserInteraction,
    errorText: errorText,
    isPassword: obscureText || onSuffixIconTap != null,
    obscureText: obscureText,
    keyboardType: keyboardType,
    autocorrect: false,
    enableSuggestions: false,
    prefixIcon: Icon(prefixIcon, size: 22),
    suffixIcon: suffixIcon == null
        ? null
        : IconButton(
            tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
            onPressed: onSuffixIconTap,
            icon: Icon(suffixIcon, size: 22),
          ),
  );
}
