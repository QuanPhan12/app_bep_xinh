import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';

class FridgeSkeleton extends StatelessWidget {
  const FridgeSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
      child: AppSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SkeletonLines(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(height: 14, width: 130),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SkeletonBlock(height: 30, width: 80, radius: 16),
                      SkeletonBlock(height: 30, width: 90, radius: 16),
                      SkeletonBlock(height: 30, width: 70, radius: 16),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SkeletonBlock(height: 50, radius: 12),
            const SizedBox(height: 24),
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: SkeletonLines(),
              ),
            const SizedBox(height: 12),
            for (var i = 0; i < 2; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: SkeletonLines(),
              ),
          ],
        ),
      ),
    ),
  );
}
