import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tap.dart';
import '../models/inbox_notification.dart';

class NotificationTile extends StatelessWidget {
  final InboxNotification item;
  final VoidCallback? onOpen;
  const NotificationTile({super.key, required this.item, required this.onOpen});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: item.isRead ? 'Đã đọc' : 'Chưa đọc',
    child: AppCard(
      child: AppTap(
        actionName: 'notification_open',
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: item.isRead ? Colors.transparent : AppColors.primary,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isRead
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : context.colors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIconsRegular.cookingPot,
                  color: item.isRead
                      ? context.colors.textSecondary
                      : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: item.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${item.isRead ? 'Đã đọc' : 'Chưa đọc'} · ${item.timeLabel}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Badge(
                    smallSize: 7,
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
