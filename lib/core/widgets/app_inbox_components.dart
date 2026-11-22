import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import '../utils/app_layout.dart';
import 'app_card.dart';
import 'app_content_scroll_view.dart';

class AppInboxBody extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final bool isPadding;
  const AppInboxBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.isPadding = true,
  });
  @override
  Widget build(BuildContext context) {
    final content = AppContentScrollView(
      padding: isPadding ? const EdgeInsets.all(16) : EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    );
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.formWidth(context)),
          child: onRefresh == null
              ? content
              : RefreshIndicator(onRefresh: onRefresh!, child: content),
        ),
      ),
    );
  }
}

class AppInboxFilters extends StatelessWidget {
  final bool unreadOnly;
  final int unreadCount;
  final ValueChanged<bool> onChanged;
  const AppInboxFilters({
    super.key,
    required this.unreadOnly,
    required this.unreadCount,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final unread in [false, true])
        ChoiceChip(
          label: Text(unread ? 'Chưa đọc ($unreadCount)' : 'Tất cả'),
          selected: unreadOnly == unread,
          showCheckmark: false,
          selectedColor: AppColors.action,
          backgroundColor: context.colors.surface,
          side: BorderSide(
            color: unreadOnly == unread
                ? AppColors.primary
                : context.colors.border,
          ),
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: unreadOnly == unread
                ? Colors.white
                : context.colors.textSecondary,
          ),
          shape: const StadiumBorder(),
          onSelected: (_) => onChanged(unread),
        ),
    ],
  );
}

class AppInboxEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const AppInboxEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );
}
