import 'chat_recipe_card.dart';

import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../models/conversation.dart';
import '../../recipes/widgets/recipe_image_view.dart';
import '../../../core/widgets/app_tap.dart';
import 'chat_image_viewer.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onOpenRecipe;
  const MessageBubble({super.key, required this.message, this.onOpenRecipe});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: constraints.maxWidth * .86),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: message.fromMe
              ? context.colors.primary50
              : Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(
            color: message.fromMe
                ? context.colors.primary100
                : Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: .4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.fromMe ? 18 : 4),
            bottomRight: Radius.circular(message.fromMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.recipe != null)
              ChatRecipeCard(recipe: message.recipe!, onTap: onOpenRecipe),
            if (message.image != null)
              Semantics(
                button: true,
                label: 'Mở ảnh',
                child: AppTap(
                  actionName: 'message_view_image',
                  onTap: message.image!.url == null
                      ? null
                      : () {
                          showChatImage(context, message.image!);
                        },
                  child: SizedBox(
                    width: 240,
                    child: RecipeImageView(
                      image: message.image!,
                      aspectRatio: 4 / 3,
                    ),
                  ),
                ),
              ),
            if ((message.image != null || message.recipe != null) &&
                message.text.isNotEmpty)
              const SizedBox(height: 10),
            if (message.text.isNotEmpty)
              SelectableText(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.textPrimary,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              message.timeLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
