import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_layout.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../cubits/kitchen_list_cubit.dart';
import '../models/kitchen_entry.dart';

class KitchenPage extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final List<Widget>? actions;
  final double maxWidth;
  const KitchenPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.actions,
    this.maxWidth = AppLayout.formMaxWidth,
  });
  static const _descriptions = {
    'Thực đơn tuần': 'Chọn ngày, sắp xếp món cho từng bữa ăn.',
    'Nguyên liệu & hạn dùng': 'Quản lý số lượng và hạn dùng. Danh sách này độc lập với bộ lọc Tủ lạnh.',
    'Bộ sưu tập': 'Gom các công thức theo sở thích và những dịp bạn muốn nấu.',
    'Nhật ký nấu ăn': 'Ghi lại món đã nấu và kinh nghiệm cho lần sau.',
    'Hẹn giờ nấu ăn': 'Đặt thời gian cho từng việc đang nấu.',
    'Công thức đã tải': 'Đọc lại công thức khi mất mạng; kiểm tra trực tuyến để cập nhật trạng thái món.',
    'Tác giả đang theo dõi': 'Tìm lại tác giả yêu thích và mở bảng tin của họ.',
    'Đang theo dõi': 'Công thức từ những tác giả bạn đang theo dõi.',
  };
  @override
  Widget build(BuildContext context) => AppPageScaffold(
    appBar: AppSliverAppBar(
      title: title,
      onBackPressed: onBack,
      actions: actions,
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_descriptions[title] != null &&
                  MediaQuery.viewInsetsOf(context).bottom == 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    _descriptions[title]!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class KitchenListBody<T extends KitchenEntry> extends StatelessWidget {
  final List<Widget> Function(BuildContext, KitchenListState<T>) children;
  const KitchenListBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<KitchenListCubit<T>, KitchenListState<T>>(
        listenWhen: (a, b) =>
            b.error != null && a.error != b.error && a.items.isNotEmpty,
        listener: (context, state) =>
            AppMessenger.showError(context, state.error!),
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const AppLoadState(isLoading: true);
          }
          if (state.error != null && state.items.isEmpty) {
            return AppLoadState(
              message: state.error,
              onRetry: context.read<KitchenListCubit<T>>().load,
            );
          }
          return AppContentScrollView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.items.length >= 500)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Đang hiển thị 500 mục cập nhật gần nhất. Một số mục cũ có thể chưa nằm trong danh sách này.',
                  ),
                ),
              ...children(context, state),
            ],
          );
        },
      );
}

Future<String?> kitchenTextDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  int maxLength = 60,
  bool multiline = false,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 5 : 1,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  // Dialog còn frame reverse trước khi field tháo khỏi cây.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  controller.dispose();
  return result;
}

Future<bool> kitchenConfirmDelete(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Xóa mục này?'),
    content: const Text('Thao tác này sẽ xóa mục đã chọn.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: const Text('Giữ lại'),
      ),
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        child: const Text('Xóa'),
      ),
    ],
  ),
).then((value) => value ?? false);
