import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';

import '../../../core/widgets/app_tap.dart';
import '../models/conversation.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onOpen;
  final String? avatarAsset;
  final String? emptyPreview;
  final bool pinned;
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onOpen,
    this.avatarAsset,
    this.emptyPreview,
    this.pinned = false,
  });
  @override
  Widget build(BuildContext context) {
    final last = conversation.messages.lastOrNull;
    final unread = conversation.unreadCount > 0;
    return Semantics(
      button: true,
      label: pinned
          ? 'Cuộc trò chuyện đã ghim'
          : unread
          ? 'Có tin nhắn chưa đọc'
          : 'Đã đọc',
      child: Material(
        color: Colors.transparent,
        child: AppTap(
          actionName: 'conversation_open',
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(
                  name: conversation.name,
                  assetPath: avatarAsset,
                  size: 44,
                  cornerRadius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : pinned
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        last == null
                            ? emptyPreview ?? 'Bắt đầu bằng một lời chào nhé!'
                            : '${last.fromMe ? 'Bạn: ' : ''}${last.text.isEmpty && last.recipe != null
                                  ? '🍽 ${last.recipe!.title}'
                                  : last.text.isEmpty && last.image != null
                                  ? 'Đã gửi một ảnh'
                                  : last.text}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      if (last != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          last.timeLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5),
                    child: Icon(
                      PhosphorIconsRegular.pushPin,
                      size: 16,
                      color: context.colors.textTertiary,
                      semanticLabel: 'Đã ghim',
                    ),
                  ),
                if (unread)
                  const Padding(
                    padding: EdgeInsets.only(left: 8, top: 5),
                    child: Badge(
                      smallSize: 8,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
