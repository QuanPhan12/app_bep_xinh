import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/utils/app_layout.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_load_state.dart';
import '../cubits/conversation_cubit.dart';
import 'chat_history_list.dart';
import 'message_bubble.dart';
import 'message_composer.dart';

class ConversationContent extends StatelessWidget {
  const ConversationContent({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ConversationCubit, ConversationState>(
    builder: (context, state) {
      final conversation = state.conversation;
      if (conversation == null) {
        return AppLoadState(
          isLoading: state.loading,
          message: state.error,
          onRetry: context.read<ConversationCubit>().load,
        );
      }
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.formWidth(context)),
          child: Column(
            children: [
              Container(
                color: context.colors.surface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppAvatar(
                      name: conversation.name,
                      size: 42,
                      cornerRadius: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.name,
                            style: AppTextStyles.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conversation.subtitle,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: conversation.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Một lời chào, một câu chuyện bếp.\nBắt đầu cuộc trò chuyện nhé!',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    : ChatHistoryList(
                        messageCount: conversation.messages.length,
                        messageBuilder: (_, index) {
                          final message = conversation.messages[index];
                          final recipe = message.recipe;
                          return MessageBubble(
                            key: ValueKey(message.id),
                            message: message,
                            onOpenRecipe: recipe == null
                                ? null
                                : () => context.push(
                                    '/recipe/${Uri.encodeComponent(recipe.id)}',
                                  ),
                          );
                        },
                        hasOlder: state.hasOlder,
                        loadingOlder: state.loadingOlder,
                        olderLoadFailed: state.olderLoadFailed,
                        onLoadOlder: context
                            .read<ConversationCubit>()
                            .loadOlder,
                      ),
              ),
              const MessageComposer(),
            ],
          ),
        ),
      );
    },
  );
}
