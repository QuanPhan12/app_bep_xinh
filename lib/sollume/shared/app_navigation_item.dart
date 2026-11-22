import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../core/theme/app_spacing.dart';

/// Port phần hiển thị NavigationSidebarItem; route và guard vẫn do Bếp Xinh cung cấp.
class AppNavigationItem extends StatelessWidget {
  const AppNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.selected = false,
    this.collapsed = false,
  });
  final String label;
  final IconData icon, selectedIcon;
  final VoidCallback onTap;
  final bool selected, collapsed;
  @override
  Widget build(BuildContext context) {
    final glyph = PhosphorIcon(selected ? selectedIcon : icon, size: 22);
    final tile = Semantics(
      label: collapsed ? label : null,
      selected: selected,
      child: ListTile(
        selected: selected,
        onTap: onTap,
        contentPadding: collapsed ? EdgeInsets.zero : null,
        leading: collapsed ? null : glyph,
        title: collapsed
            ? Center(child: glyph)
            : Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: collapsed
          ? Tooltip(message: 'Đi đến $label', excludeFromSemantics: true, child: tile)
          : tile,
    );
  }
}
