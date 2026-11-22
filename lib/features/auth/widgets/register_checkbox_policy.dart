import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/app_tap.dart';
import '../cubits/register/register.dart';

class RegisterCheckboxPolicy extends StatefulWidget {
  const RegisterCheckboxPolicy({super.key});

  @override
  State<RegisterCheckboxPolicy> createState() => _RegisterCheckboxPolicyState();
}

class _RegisterCheckboxPolicyState extends State<RegisterCheckboxPolicy> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/legal/terms');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/legal/privacy');
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<RegisterCubit, RegisterState, (bool, bool)>(
        selector: (state) =>
            (state.isTermsAccepted, state.status == RegisterStatus.loading),
        builder: (context, value) {
          final baseStyle = AppTextStyles.bodySmall.copyWith(
            color: context.colors.textSecondary,
            height: 1.5,
          );
          final linkStyle = baseStyle.copyWith(
            color: AppColors.action,
            fontWeight: FontWeight.w600,
            // decoration: TextDecoration.underline,
            decorationColor: AppColors.action,
          );

          return Semantics(
            checked: value.$1,
            enabled: !value.$2,
            label: 'Đồng ý với Điều khoản dịch vụ và Chính sách bảo mật',
            child: AppTap(
              actionName: 'toggle_terms_checkbox',
              onTap: value.$2
                  ? null
                  : context.read<RegisterCubit>().toggleTermsAccepted,
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: Checkbox(
                        value: value.$1,
                        activeColor: AppColors.action,
                        onChanged: value.$2 ? null : (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text.rich(
                        TextSpan(
                          style: baseStyle,
                          children: [
                            const TextSpan(text: 'Tôi đồng ý với '),
                            TextSpan(
                              text: 'Điều khoản dịch vụ',
                              style: linkStyle,
                              recognizer: _termsRecognizer,
                            ),
                            const TextSpan(text: ' và '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: linkStyle,
                              recognizer: _privacyRecognizer,
                            ),
                            const TextSpan(text: '.'),
                          ],
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