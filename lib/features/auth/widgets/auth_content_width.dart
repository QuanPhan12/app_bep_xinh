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
      child: child,
    ),
  );
}
