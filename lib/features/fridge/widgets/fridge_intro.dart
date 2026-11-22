import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';

class FridgeIntro extends StatelessWidget {
  const FridgeIntro({super.key});
  @override
  Widget build(BuildContext context) => Text(
    'Tủ lạnh',
    style: AppTextStyles.headlineSmall.copyWith(
      fontSize: 30,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -.8,
    ),
  );
}
