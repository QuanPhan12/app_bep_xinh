import 'package:flutter/material.dart';

import '../../sollume/shared/app_tab_bar.dart';

class AppTabs extends StatefulWidget {
  const AppTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.isScrollable = false,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isScrollable;
  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _controller = TabController(
      length: widget.labels.length,
      initialIndex: widget.selectedIndex,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AppTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      _controller.dispose();
      _create();
    } else if (_controller.index != widget.selectedIndex) {
      _controller.index = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTabBar(
    tabs: widget.labels,
    controller: _controller,
    isScrollable: widget.isScrollable,
    onTap: (index) {
      if (index != widget.selectedIndex) widget.onSelected(index);
      // Router/Cubit xác nhận lựa chọn; guard từ chối không để indicator lệch trạng thái.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.index != widget.selectedIndex) {
          _controller.index = widget.selectedIndex;
        }
      });
    },
  );
}
