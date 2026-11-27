import 'package:flutter/material.dart';

/// Số đầy đủ cho accessibility, số gọn cho hàng hành động trên màn hẹp.
class PostAction extends StatelessWidget {
  const PostAction({
    super.key,
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.unit,
    this.onPressed,
    this.selected = false,
  });
  final IconData icon;
  final int? count;
  final String tooltip, unit;
  final VoidCallback? onPressed;
  final bool selected;

  static String compact(int count) {
    if (count < 1000) return '$count';
    final divisor = count < 1000000 ? 1000 : 1000000;
    final value = ((count * 10 ~/ divisor) / 10)
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '');
    return '$value${divisor == 1000 ? 'k' : 'M'}';
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    excludeFromSemantics: true,
    child: Semantics(
      label: count == null
          ? '$tooltip, chưa có số liệu'
          : '$tooltip, $count $unit',
      selected: selected,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        icon: ExcludeSemantics(child: Icon(icon, size: 20)),
        label: ExcludeSemantics(
          child: Text(count == null ? '—' : compact(count!)),
        ),
      ),
    ),
  );
}
