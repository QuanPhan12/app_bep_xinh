import 'package:flutter/material.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_theme.dart';

/// Nhóm menu dùng cùng kiểu tiêu đề, khoảng cách và đường phân cách.
class AppMenuSection extends StatelessWidget {
  const AppMenuSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.muted  ,
        )),
      ),
      // SizedBox(height: AppSpacing.resolve(context, AppSpacing.lg)),
      for (final child in children) ...[child],
    ],
  );
}
