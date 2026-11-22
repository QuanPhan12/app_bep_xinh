import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_theme.dart';

import 'app_tap.dart';

/// Hàng menu có icon đầu hàng, nhãn, thông tin phụ và mũi tên.
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.leadingIcon,
    this.trailingIcon = PhosphorIconsBold.caretRight,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final IconData? leadingIcon;
  final IconData trailingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final metrics = AppResponsive.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: AppTap(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: metrics.control(56)),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                if (leadingIcon != null) ...[
                  ExcludeSemantics(
                    child: PhosphorIcon(
                      leadingIcon!,
                      size: metrics.size(22),
                      color: context.appColors.text,
                    ),
                  ),
                  SizedBox(width: metrics.size(AppSpacing.sm)),
                ],
                Expanded(
                  child: subtitle == null
                      ? Text(
                          title,
                          style:
                              titleStyle ??
                              text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style:
                                  titleStyle ??
                                  text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            SizedBox(height: metrics.size(AppSpacing.xxs)),
                            Text(
                              subtitle!,
                              style: text.bodySmall?.copyWith(
                                color: context.appColors.muted,
                              ),
                            ),
                          ],
                        ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: metrics.size(AppSpacing.sm)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .4,
                    ),
                    child: trailing,
                  ),
                ],
                SizedBox(width: metrics.size(AppSpacing.sm)),
                ExcludeSemantics(
                  child: Icon(
                    trailingIcon,
                    size: metrics.size(18),
                    color: context.appColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
