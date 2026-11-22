import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ProfileRecipeEmptyState extends StatelessWidget {
  const ProfileRecipeEmptyState({
    super.key,
    required this.saved,
    required this.filtered,
    required this.onCreate,
    required this.onExplore,
    required this.onClearFilter,
  });
  final bool saved, filtered;
  final VoidCallback onCreate, onExplore, onClearFilter;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                filtered
                    ? PhosphorIconsRegular.funnel
                    : saved
                    ? PhosphorIconsRegular.bookmarkSimple
                    : PhosphorIconsRegular.forkKnife,
                color: scheme.onSurfaceVariant,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            filtered
                ? 'Không có món phù hợp'
                : saved
                ? 'Chưa có món đã lưu'
                : 'Chưa có công thức',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Thử bỏ bộ lọc để xem tất cả công thức.'
                : saved
                ? 'Lưu món bạn thích để dễ tìm lại khi vào bếp.'
                : 'Chia sẻ món tủ và những bí quyết nấu ăn của bạn với mọi người.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: filtered
                ? TextButton(
                    onPressed: onClearFilter,
                    child: const Text('Xóa bộ lọc'),
                  )
                : saved
                ? OutlinedButton(
                    onPressed: onExplore,
                    child: const Text('Khám phá công thức'),
                  )
                : FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                    label: const Text(
                      'Đăng công thức đầu tiên',
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
