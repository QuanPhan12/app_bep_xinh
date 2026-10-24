import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class FridgeIntro extends StatelessWidget {
  const FridgeIntro({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tủ lạnh thông minh',
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Chọn nguyên liệu để tìm món phù hợp.',
        style: AppTextStyles.bodySmall,
      ),
    ],
  );
}
