import 'package:flutter/material.dart';

import '../../sollume/shared/app_menu_section.dart';
import '../../sollume/core/theme/app_theme.dart';

class AppMenuGroup extends StatelessWidget {
  const AppMenuGroup({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: AppSpacing.resolve(context, AppSpacing.xl),
    ),
    child: AppMenuSection(title: title, children: children),
  );
}
