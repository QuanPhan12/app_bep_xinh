import 'package:flutter/material.dart';

import '../../sollume/shared/app_menu_tile.dart';

/// Hàng thao tác cùng nhịp với menu Sollume; caller sở hữu điều hướng và nghiệp vụ.
class AppFeatureTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const AppFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => AppMenuTile(
    title: title,
    subtitle: subtitle,
    leadingIcon: icon,
    onTap: onTap,
  );
}
