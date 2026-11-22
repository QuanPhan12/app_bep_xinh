import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_messenger.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../screens/cooking_timers_screen.dart';
import 'cooking_timer_card.dart';

class RecipeActiveTimers extends StatelessWidget {
  final String recipeTitle;
  const RecipeActiveTimers({super.key, required this.recipeTitle});
  @override
  Widget build(BuildContext context) {
    final kitchen = KitchenScope.maybeOf(context);
    if (kitchen == null || !kitchen.signedIn) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => CookingTimersCubit(kitchen.timers)..load(),
      child: BlocConsumer<CookingTimersCubit, CookingTimersState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) =>
            AppMessenger.showError(context, state.error!),
        builder: (context, state) {
          final cubit = context.read<CookingTimersCubit>();
          return Column(
            children: [
              for (final timer in state.items.where(
                (t) => t.label.startsWith('$recipeTitle · Bước '),
              ))
                CookingTimerCard(
                  timer: timer,
                  now: cubit.service.now(),
                  busy: state.busy,
                  onToggle: () {
                    cubit.run(() => cubit.service.toggle(timer.id));
                  },
                  onRemove: () {
                    cubit.run(() => cubit.service.remove(timer.id));
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
