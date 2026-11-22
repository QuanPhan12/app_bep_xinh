import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../themes/app_theme_cubit.dart';
import 'app_messenger.dart';

class AppAppearancePicker extends StatelessWidget {
  final bool compact;
  const AppAppearancePicker({super.key, this.compact = false});
  static String label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Theo hệ thống',
    ThemeMode.light => 'Sáng',
    ThemeMode.dark => 'Tối',
  };
  @override
  Widget build(BuildContext context) {
    AppThemeCubit? cubit;
    try {
      cubit = context.read<AppThemeCubit>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    final theme = cubit;
    return BlocBuilder<AppThemeCubit, ThemeMode>(
      builder: (context, mode) {
        Future<void> show() => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          useSafeArea: true,
          builder: (sheetContext) => BlocProvider.value(
            value: theme,
            child: BlocBuilder<AppThemeCubit, ThemeMode>(
              builder: (context, current) => SingleChildScrollView(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Giao diện',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      for (final option in ThemeMode.values)
                        ListTile(
                          leading: Icon(switch (option) {
                            ThemeMode.system => Icons.brightness_auto_outlined,
                            ThemeMode.light => Icons.light_mode_outlined,
                            ThemeMode.dark => Icons.dark_mode_outlined,
                          }),
                          title: Text(label(option)),
                          trailing: current == option
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () async {
                            final saved = await theme.select(option);
                            if (sheetContext.mounted) {
                              if (!saved) {
                                AppMessenger.showError(
                                  sheetContext,
                                  'Đã đổi giao diện trong phiên này, chưa lưu được trên thiết bị.',
                                );
                              }
                              Navigator.of(sheetContext).pop();
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        if (compact) {
          return IconButton(
            tooltip: 'Giao diện',
            onPressed: show,
            icon: Icon(
              mode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          );
        }
        return ListTile(
          leading: const Icon(Icons.contrast),
          title: const Text('Giao diện'),
          subtitle: Text(label(mode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: show,
        );
      },
    );
  }
}
