import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_inbox_components.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../cubits/messages_cubit.dart';
import 'conversation_tile.dart';
import '../../ai_chat/widgets/ai_chat_entry.dart';

class MessagesContent extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const MessagesContent({super.key, required this.onOpen});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MessagesCubit, MessagesState>(
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
                const SizedBox(
                  height: 280,
                  child: AppLoadState(isLoading: true),
                )
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
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: ConversationTile(
                    conversation: item,
                    onOpen: () => onOpen(item.id),
                  ),
                ),
            ],
          );
        },
      );
}
