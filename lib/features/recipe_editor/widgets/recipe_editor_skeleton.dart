import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';

class RecipeEditorSkeleton extends StatelessWidget {
  const RecipeEditorSkeleton({super.key});
  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(height: 12, width: 100),
        ),
        const SizedBox(height: 12),
        const AspectRatio(
          aspectRatio: 16 / 9,
          child: SkeletonBlock(height: 180, radius: 12),
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(height: 12, width: 100),
        ),
        const SizedBox(height: 12),
        const SkeletonBlock(height: 48, radius: 12),
        const SizedBox(height: 40),
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(height: 16, width: 140),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: SkeletonBlock(height: 66, radius: 12)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBlock(height: 66, radius: 12)),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonLines(),
        const SizedBox(height: 40),
        const SkeletonLines(),
        const SizedBox(height: 40),
        const SkeletonBlock(height: 100, radius: 12),
      ],
    ),
  );
}
