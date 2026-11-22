import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../text_styles/app_text_styles.dart';
import 'app_button.dart';
import 'app_skeleton.dart';

/// Trạng thái tải/lỗi/rỗng dùng chung, giữ callback để có thể thử lại.
class AppLoadState extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final FutureOr<void> Function()? onRetry;
  final Widget? skeleton;

  const AppLoadState({
    super.key,
    this.isLoading = false,
    this.message,
    this.onRetry,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) => isLoading
      ? skeleton ?? const AppContentSkeleton()
      : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      onRetry == null
                          ? PhosphorIconsRegular.forkKnife
                          : PhosphorIconsRegular.arrowClockwise,
                      size: 26,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    message ?? 'Chưa có dữ liệu.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Thử lại',
                    onPressed: onRetry,
                    isFullWidth: false,
                  ),
                ],
              ],
            ),
          ),
        );
}
