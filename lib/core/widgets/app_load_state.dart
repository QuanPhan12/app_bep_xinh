import 'dart:async';

import 'package:flutter/material.dart';

import '../text_styles/app_text_styles.dart';
import 'app_button.dart';
import 'app_skeleton.dart';
import 'app_feature_theme.dart';

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
                if (AppFeatureTheme.isActive(context)) ...[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppFeatureTheme.herbWash,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      onRetry == null
                          ? Icons.restaurant_menu_rounded
                          : Icons.refresh_rounded,
                      size: 30,
                      color: AppFeatureTheme.herb,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  message ?? 'Chưa có dữ liệu.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
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
