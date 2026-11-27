import '../../recipes/widgets/recipe_image_view.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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
        previous.draft.photos != current.draft.photos ||
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: state.errors['cover'] == null
                      ? null
                      : Border.all(color: context.colors.error),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIconsRegular.cameraPlus,
                                size: 24,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Thêm ảnh bìa',
                              style: AppTextStyles.labelLarge,
                            ),
                          ],
                        )
                      else ...[
                        RecipeImageView(image: photo),
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
          TextButton.icon(
            key: const ValueKey('recipe_add_photos'),
            onPressed: state.isBusy ? null : cubit.addPhotos,
            icon: const Icon(PhosphorIconsBold.images),
            label: Text(
              'Thêm ảnh (${(photo == null ? 0 : 1) + state.draft.photos.length}/10)',
            ),
          ),
          if (state.draft.photos.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final image in state.draft.photos)
                  SizedBox(
                    key: ValueKey('recipe_photo_${image.id}'),
                    width: 132,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: RecipeImageView(image: image),
                        ),
                        TextButton(
                          onPressed: state.isBusy
                              ? null
                              : () => cubit.makeCover(image.id),
                          child: const Text('Làm ảnh bìa'),
                        ),
                        IconButton(
                          tooltip: 'Xóa ảnh',
                          onPressed: state.isBusy
                              ? null
                              : () => cubit.removePhoto(image.id),
                          icon: const Icon(PhosphorIconsBold.trash),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          TextButton.icon(
            onPressed: state.isBusy
                ? null
                : () => cubit.pickCover(camera: true),
            icon: const Icon(PhosphorIconsRegular.camera),
            label: const Text('Chụp ảnh món ăn'),
          ),
          if (state.errors['cover'] case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
        ],
      );
    },
  );
}
