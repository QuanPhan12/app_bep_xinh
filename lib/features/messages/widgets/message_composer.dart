import 'dart:async';

import 'chat_recipe_card.dart';
import 'chat_recipe_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_text_field.dart';
import '../cubits/conversation_cubit.dart';
import 'chat_attachment_preview.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({super.key});
  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  int _sentVersion = 0;
  void _pickRecipe() {
    final cubit = context.read<ConversationCubit>();
    FocusScope.of(context).unfocus();
    // Mở sheet không giữ khóa tap toàn app; tải/thử lại do Cubit của picker quản lý.
    unawaited(
      cubit.pickRecipe(() => showChatRecipePicker(context, cubit.repository)),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ConversationCubit, ConversationState>(
    listenWhen: (previous, next) =>
        previous.sending &&
        !next.sending &&
        next.draft.isEmpty &&
        next.image == null &&
        next.recipe == null &&
        next.error == null,
    listener: (_, _) => setState(() => _sentVersion++),
    builder: (context, state) => Material(
      color: context.colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.image != null)
                ChatAttachmentPreview(
                  image: state.image!,
                  sending: state.sending,
                  uploading: state.uploadingImage,
                  onRemove: context.read<ConversationCubit>().removeImage,
                ),
              if (state.recipe != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChatRecipeCard(
                    recipe: state.recipe!,
                    sending: state.sending,
                    onRemove: context.read<ConversationCubit>().removeRecipe,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Đính kèm',
                    enabled:
                        !state.sending &&
                        !state.pickingImage &&
                        !state.pickingRecipe &&
                        state.conversation != null,
                    icon: state.pickingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(PhosphorIconsRegular.plusCircle, size: 22),
                    onSelected: (value) {
                      if (value == 'recipe') {
                        context
                            .onAppTap(
                              _pickRecipe,
                              actionName: 'message_pick_recipe',
                            )
                            ?.call();
                      } else {
                        context
                            .onAppTap(
                              context.read<ConversationCubit>().pickImage,
                              actionName: 'message_pick_image',
                            )
                            ?.call();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'image',
                        enabled:
                            context.read<ConversationCubit>().images != null,
                        child: const Row(
                          children: [
                            Icon(PhosphorIconsRegular.image, size: 20),
                            SizedBox(width: 12),
                            Expanded(child: Text('Chọn ảnh')),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'recipe',
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.bookOpen, size: 20),
                            SizedBox(width: 12),
                            Expanded(child: Text('Chọn công thức')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: AppTextField(
                      // Sau khi gửi thành công mới thay field để xóa nội dung; lỗi giữ nguyên bản nháp.
                      key: ValueKey(_sentVersion),
                      fieldId: 'message_draft',
                      initialValue: state.draft,
                      hint: 'Viết một lời nhắn…',
                      maxLength: 2000,
                      showCounter: false,
                      minLines: 1,
                      maxLines: state.image == null && state.recipe == null
                          ? 4
                          : 2,
                      enabled: !state.sending,
                      onChanged: context.read<ConversationCubit>().changeDraft,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Gửi tin nhắn',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: state.canSend
                        ? context.onAppTap(
                            context.read<ConversationCubit>().send,
                            actionName: 'message_send',
                          )
                        : null,
                    icon: state.sending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(
                            PhosphorIconsRegular.paperPlaneTilt,
                            size: 21,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${state.draft.characters.length}/2000',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
