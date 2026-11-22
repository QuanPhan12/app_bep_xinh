import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../recipes/models/recipe_image.dart';
import '../../recipes/widgets/recipe_image_view.dart';

class ChatAttachmentPreview extends StatelessWidget {
  final RecipeImage image;
  final bool sending;
  final bool uploading;
  final VoidCallback onRemove;
  const ChatAttachmentPreview({
    super.key,
    required this.image,
    required this.sending,
    required this.uploading,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 64,
              height: 48,
              child: RecipeImageView(image: image, aspectRatio: 4 / 3),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                uploading
                    ? 'Đang tải ảnh…'
                    : sending
                    ? 'Đang gửi…'
                    : 'Ảnh đã chọn',
                style: AppTextStyles.labelMedium,
              ),
            ),
            IconButton(
              tooltip: 'Bỏ ảnh',
              onPressed: sending ? null : onRemove,
              icon: const Icon(PhosphorIconsRegular.x, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ảnh được chia sẻ qua liên kết; người có liên kết có thể xem.',
          style: AppTextStyles.labelSmall.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ],
    ),
  );
}
