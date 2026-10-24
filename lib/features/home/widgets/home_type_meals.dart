import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class HomeTypeMeals extends StatelessWidget {
  final String title;
  final String image;
  const HomeTypeMeals({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return AppTap(
      actionName: 'home_type_meal_$title',
      onTap: () {},
      child: SizedBox(
        width: 80.w(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 30, backgroundImage: AssetImage(image)),
            SizedBox(height: 8.h(context)),
            SizedBox(
              width: 80.w(context),
              height: 40.h(context),
              child: Text(
                title,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
