import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
      child: AppSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SkeletonBlock(height: 48, radius: 24),
            const SizedBox(height: 20),
            const AspectRatio(
              aspectRatio: 1.8,
              child: SkeletonBlock(height: 200, radius: 18),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 5; i++)
                  const Column(
                    children: [
                      SkeletonBlock(height: 44, width: 44, radius: 24),
                      SizedBox(height: 8),
                      SkeletonBlock(height: 8, width: 38),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const AppCard(
              padding: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SkeletonLines(),
              ),
            ),
            const SizedBox(height: 24),
            const SkeletonBlock(height: 18, width: 180),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: .8,
                    child: SkeletonBlock(height: 200, radius: 16),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: .8,
                    child: SkeletonBlock(height: 200, radius: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
