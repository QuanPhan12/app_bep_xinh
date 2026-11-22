import 'package:flutter/material.dart';

import 'app_sliver_app_bar.dart';

/// Khung màn con giữ thanh tiêu đề cố định, kể cả khi đổi trạng thái tải/lỗi.
/// AppBar có viewport riêng để thao tác đưa ô nhập vào vùng nhìn thấy
/// không cuộn nội dung lên sau thanh tiêu đề của màn con.
class AppPageScaffold extends StatelessWidget {
  final AppSliverAppBar appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  const AppPageScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(
        kToolbarHeight + (appBar.bottom?.preferredSize.height ?? 0),
      ),
      child: CustomScrollView(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [appBar],
      ),
    ),
    body: body,
    bottomNavigationBar: bottomNavigationBar,
  );
}
