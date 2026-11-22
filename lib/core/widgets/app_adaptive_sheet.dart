import 'package:flutter/material.dart';

import '../utils/app_layout.dart';

/// Tablet dùng dialog có khoảng trống quanh nội dung; điện thoại dùng sheet.
/// Dialog tự trừ bàn phím, builder chỉ nhận vùng còn lại để tránh trừ hai lần.
Future<T?> showAppAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool showDragHandle = true,
}) {
  if (AppLayout.isTablet(context)) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: backgroundColor,
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.sheetMaxWidth),
          child: MediaQuery.removeViewInsets(
            context: dialogContext,
            removeBottom: true,
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    constraints: BoxConstraints(maxWidth: AppLayout.sheetWidth(context)),
    builder: builder,
  );
}
