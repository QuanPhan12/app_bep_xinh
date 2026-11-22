import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_inbox_components.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../../core/widgets/app_messenger.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../cubits/messages_cubit.dart';
import '../models/conversation.dart';
import 'conversation_tile.dart';
import '../../ai_chat/widgets/ai_chat_entry.dart';

class MessagesContent extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const MessagesContent({super.key, required this.onOpen});

  Future<void> _confirmDelete(BuildContext context, Conversation item) async {
    final cubit = context.read<MessagesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện?'),
        content: Text(
          'Lịch sử trò chuyện với ${item.name} sẽ được xóa khỏi hộp thư của bạn. Người kia vẫn giữ tin nhắn. Hội thoại sẽ xuất hiện lại khi có tin mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await cubit.deleteConversation(item.id);
    if (context.mounted && !deleted) {
      AppMessenger.showError(
        context,
        'Chưa xóa được cuộc trò chuyện. Bạn thử lại nhé.',
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MessagesCubit, MessagesState>(
    builder: (context, state) {
      final cubit = context.read<MessagesCubit>();
      final showAi =
          !state.unreadOnly &&
          (state.query.trim().isEmpty ||
              'bếp xinh ai bep xinh ai trợ lý nấu ăn'.contains(
                state.query.trim().toLowerCase(),
              ));
      return AppInboxBody(
        isPadding: false,
        onRefresh: cubit.load,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16.0),
            child: AppSearchBar(
              hintText: 'Tìm cuộc trò chuyện',
              initialValue: state.query,
              fieldKey: const ValueKey('messages_search'),
              onChanged: cubit.search,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16.0),
            child: AppInboxFilters(
              unreadOnly: state.unreadOnly,
              unreadCount: state.items
                  .where((item) => item.unreadCount > 0)
                  .length,
              onChanged: cubit.filterUnread,
            ),
          ),
          const SizedBox(height: 16),
          if (showAi) const AiChatEntry(),
          if (state.loading && state.items.isEmpty)
            const SizedBox(height: 280, child: AppLoadState(isLoading: true))
          else if (state.error != null)
            AppLoadState(message: state.error, onRetry: cubit.load),
          if (!state.loading &&
              state.error == null &&
              !showAi &&
              state.visibleItems.isEmpty)
            AppInboxEmpty(
              icon: PhosphorIconsRegular.chatCircleDots,
              title: state.query.isNotEmpty
                  ? 'Chưa tìm thấy cuộc trò chuyện'
                  : state.unreadOnly
                  ? 'Không có tin nhắn chưa đọc'
                  : 'Gửi lời chào đầu tiên',
              description: state.query.isNotEmpty
                  ? 'Thử tìm bằng tên khác nhé.'
                  : 'Chạm nút soạn tin ở góc trên để trò chuyện với một người chia sẻ công thức.',
            ),
          for (final item in state.visibleItems)
            Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: ConversationTile(
                      conversation: item,
                      onOpen: () => onOpen(item.id),
                    ),
                  ),
                  if (state.deletingId == item.id)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Đang xóa cuộc trò chuyện',
                        ),
                      ),
                    )
                  else
                    PopupMenuButton<bool>(
                      tooltip: 'Tùy chọn cuộc trò chuyện với ${item.name}',
                      enabled: state.deletingId == null,
                      icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                      onSelected: (_) => _confirmDelete(context, item),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: true,
                          child: Text('Xóa cuộc trò chuyện'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
