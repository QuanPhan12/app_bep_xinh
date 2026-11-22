import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        AppAssets.logo,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              PhosphorIconsRegular.forkKnife,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
