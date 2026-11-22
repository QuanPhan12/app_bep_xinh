import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/tap/app_tap_handler.dart';
import '../../../core/text_styles/app_text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final bool isLoading;
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed == null || isLoading
        ? null
        : AppTapHandler.wrap(
            context,
            onTap: onPressed!,
            actionName: 'login_google',
            throttleDuration: const Duration(milliseconds: 600),
          ),
    icon: isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Image.asset(AppAssets.googleIcon, width: 20, height: 20),
    label: Text('Tiếp tục với Google', style: AppTextStyles.labelLarge),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F1F1F),
      side: const BorderSide(color: Color(0xFF747775)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
