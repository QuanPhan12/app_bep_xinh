import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:flutter/material.dart';

/// One mobile composition at every size; tablet only limits its line length.
class AuthContentWidth extends StatelessWidget {
  final Widget child;
  const AuthContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.compactMaxWidth),
      // Giữ nguyên cây form khi resize để không mất focus, selection và nội dung.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MediaQuery.sizeOf(context).width >= AppLayout.tabletBreakpoint
              ? Theme.of(context).colorScheme.surfaceContainerLow
              : Colors.transparent,
          border: Border.all(
            color:
                MediaQuery.sizeOf(context).width >= AppLayout.tabletBreakpoint
                ? Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: .45)
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding:
              MediaQuery.sizeOf(context).width >= AppLayout.tabletBreakpoint
              ? const EdgeInsets.all(24)
              : EdgeInsets.zero,
          child: child,
        ),
      ),
    ),
  );
}
