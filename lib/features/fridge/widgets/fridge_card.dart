import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';

import '../models/fridge_summary.dart';

class FridgeCard extends StatelessWidget {
  final VoidCallback onExploreTap;
  final FridgeSummary summary;
  const FridgeCard({
    super.key,
    required this.onExploreTap,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppLayout.pageWidth(context)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          decoration: BoxDecoration(
            color: context.colors.secondaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.snowflake,
                    color: context.colors.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tủ lạnh thông minh',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gợi ý',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                summary.ingredientNames.isEmpty
                    ? 'Thêm nguyên liệu bạn đang có để tìm món phù hợp.'
                    : 'Gợi ý từ ${summary.ingredientNames.take(3).join(', ')}${summary.ingredientNames.length > 3 ? '…' : '.'}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Nấu được ${summary.readyRecipeCount} món ngon',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppTextAction(
                    label: 'Khám phá ngay',
                    trailingIcon: PhosphorIconsRegular.arrowRight,
                    actionName: 'home_smart_fridge_explore_tap',
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onTap: onExploreTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
