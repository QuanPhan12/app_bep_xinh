import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_empty_state.dart';

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
    return AppEmptyState(
      title: filtered
          ? 'Không có món phù hợp'
          : saved
          ? 'Chưa có món đã lưu'
          : 'Chưa có công thức',
      message: filtered
          ? 'Thử bỏ bộ lọc để xem tất cả công thức.'
          : saved
          ? 'Lưu món bạn thích để dễ tìm lại khi vào bếp.'
          : 'Chia sẻ món tủ và những bí quyết nấu ăn của bạn với mọi người.',
      action: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: filtered
            ? TextButton(
                onPressed: onClearFilter,
                child: const Text('Xóa bộ lọc'),
              )
            : saved
            ? TextButton(
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
    );
  }
}
