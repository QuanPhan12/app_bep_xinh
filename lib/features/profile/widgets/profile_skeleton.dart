import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});
  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: AppContentScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        const Row(
          children: [
            SkeletonBlock(height: 68, width: 68, radius: 34),
            SizedBox(width: 16),
            Expanded(child: SkeletonLines()),
          ],
        ),
        const SizedBox(height: 20),
        const SkeletonBlock(height: 12),
        const SizedBox(height: 8),
        const FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: .65,
          child: SkeletonBlock(height: 12),
        ),
        const SizedBox(height: 24),
        const SkeletonBlock(height: 48),
        const SizedBox(height: 24),
        const SkeletonBlock(height: 42),
        const SizedBox(height: 28),
        const SkeletonBlock(height: 40, radius: 20),
        const SizedBox(height: 20),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              const Expanded(
                child: AspectRatio(
                  aspectRatio: .72,
                  child: SkeletonBlock(height: 220, radius: 16),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
