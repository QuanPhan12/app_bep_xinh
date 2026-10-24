import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import 'recipe_editor_section.dart';

class RecipeCoverField extends StatelessWidget {
  const RecipeCoverField({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RecipeEditorCubit, RecipeEditorState>(
    buildWhen: (previous, current) =>
        previous.draft.cover != current.draft.cover ||
        previous.operation != current.operation ||
        previous.errors['cover'] != current.errors['cover'],
    builder: (context, state) {
      final cubit = context.read<RecipeEditorCubit>();
      final photo = state.draft.cover;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Ảnh bìa món ăn', style: AppTextStyles.labelMedium),
              ),
              if (photo != null)
                RecipeEditorRemoveAction(
                  label: 'Xóa ảnh bìa',
                  onTap: state.isBusy ? null : cubit.removeCover,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: photo == null ? 'Chọn ảnh bìa' : 'Đổi ảnh bìa',
            child: AppTap(
              key: const ValueKey('recipe_cover_picker'),
              actionName: 'recipe_editor_cover',
              onTap: state.isBusy ? null : cubit.pickCover,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.errors['cover'] == null
                        ? AppColors.border
                        : AppColors.error,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photo == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 28,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Thêm ảnh bìa',
                              style: AppTextStyles.labelLarge,
                            ),
                          ],
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) => Image.memory(
                            photo.bytes,
                            fit: BoxFit.cover,
                            cacheWidth:
                                (constraints.maxWidth *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round()
                                    .clamp(1, 1600),
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Đổi ảnh',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (state.operation == RecipeEditorOperation.pickingCover)
                        const AppSkeleton(
                          child: SkeletonBlock(
                            height: double.infinity,
                            radius: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (state.errors['cover'] case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
        ],
      );
    },
  );
}
