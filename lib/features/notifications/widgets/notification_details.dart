import 'package:flutter/material.dart';

import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../models/inbox_notification.dart';

Future<void> showNotificationDetails(
  BuildContext context, {
  required InboxNotification item,
  required VoidCallback onViewRecipe,
}) => showAppAdaptiveSheet<void>(
  context: context,
  builder: (sheetContext) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title, style: AppTextStyles.titleLarge),
              ),
              IconButton(
                tooltip: 'Đóng thông báo',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.timeLabel, style: AppTextStyles.labelSmall),
          const SizedBox(height: 20),
          Text(item.body, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          AppButton(
            text: item.recipeId != null ? 'Xem công thức' : 'Xem bài đã gửi',
            onPressed: () {
              Navigator.of(sheetContext).pop();
              onViewRecipe();
            },
          ),
        ],
      ),
    ),
  ),
);
