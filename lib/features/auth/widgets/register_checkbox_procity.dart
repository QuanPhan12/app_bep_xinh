import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../cubits/register/register.dart';

/// Widget Checkbox xác nhận đồng ý với Điều khoản dịch vụ và Chính sách bảo mật Bếp Xinh
class RegisterCheckboxProcity extends StatelessWidget {
  const RegisterCheckboxProcity({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RegisterCubit, RegisterState, bool>(
      selector: (state) => state.isTermsAccepted,
      builder: (context, isAccepted) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox với animation mượt mà
            AppTap(
              actionName: 'toggle_terms_checkbox',
              onTap: () => context.read<RegisterCubit>().toggleTermsAccepted(),
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 10, bottom: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isAccepted ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAccepted
                          ? AppColors.primary
                          : AppColors.borderDark,
                      width: 1.8,
                    ),
                    boxShadow: isAccepted
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isAccepted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),

            // Đoạn văn bản đồng ý với clickable links
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Tôi đồng ý với ',
                  style: AppTextStyles.labelMedium.copyWith(height: 1.45),
                  children: [
                    TextSpan(
                      text: 'Điều khoản dịch vụ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Chính sách bảo mật',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
