import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../cubits/chat_recipes_cubit.dart';
import '../models/chat_recipe.dart';
import '../services/message_repository.dart';
import 'chat_recipe_card.dart';

Future<ChatRecipe?> showChatRecipePicker(
  BuildContext context,
  MessageRepository repository,
) => showAppAdaptiveSheet<ChatRecipe>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => ChatRecipesCubit(repository)..load(),
    child: const _ChatRecipePicker(),
  ),
);

class _ChatRecipePicker extends StatelessWidget {
  const _ChatRecipePicker();
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(
      height:
          (MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom) *
          .7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gửi công thức',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSearchBar(
              hintText: 'Tìm công thức…',
              onChanged: context.read<ChatRecipesCubit>().search,
              fieldKey: const ValueKey('chat_recipe_search'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ChatRecipesCubit, ChatRecipesState>(
                builder: (context, state) {
                  if (state.loading || state.error != null) {
                    return AppLoadState(
                      isLoading: state.loading,
                      message: state.error,
                      onRetry: context.read<ChatRecipesCubit>().load,
                    );
                  }
                  if (state.visible.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có công thức công khai phù hợp.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: state.visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => ChatRecipeCard(
                      recipe: state.visible[index],
                      onTap: () => Navigator.pop(context, state.visible[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
