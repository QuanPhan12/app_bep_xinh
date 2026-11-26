import 'package:flutter/material.dart';

import '../../../sollume/shared/app_menu_section.dart';

/// Nhãn nhóm theo menu Sollume; phần nội dung không thêm khung hoặc nền riêng.
class RecipeSection extends StatelessWidget {
  const RecipeSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: AppMenuSection(title: title, children: const []),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}
