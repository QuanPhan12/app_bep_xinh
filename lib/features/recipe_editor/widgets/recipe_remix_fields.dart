import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../recipes/widgets/recipe_remix_attribution.dart';
import '../cubits/recipe_editor/recipe_editor_cubit.dart';

class RecipeRemixFields extends StatelessWidget {
  const RecipeRemixFields({super.key, this.readOnly = false});
  final bool readOnly;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RecipeEditorCubit, RecipeEditorState>(
    builder: (context, state) {
      final remix = state.draft.remix;
      if (remix == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RecipeRemixAttribution(
              remix: remix,
              showChanges: readOnly,
              onOpen: () => context.push(
                '/recipe/${Uri.encodeComponent(remix.recipeId)}',
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(height: 16),
              AppTextField(
                fieldId: 'recipe_remix_changes',
                initialValue: remix.changes,
                label: 'Bạn đã điều chỉnh gì?',
                hint: 'Ví dụ: giảm đường và thay thịt bằng nấm…',
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                enabled: !state.isBusy,
                error: state.errors['remixChanges'],
                onChanged: context.read<RecipeEditorCubit>().changeRemixChanges,
              ),
            ],
            if (state.errors['remixContent'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errors['remixContent']!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      );
    },
  );
}
