import 'package:flutter/material.dart';

class ChatHistoryList extends StatelessWidget {
  final ScrollController? controller;
  final int messageCount;
  final IndexedWidgetBuilder messageBuilder;
  final Widget? pending;
  final bool hasOlder;
  final bool loadingOlder;
  final bool olderLoadFailed;
  final VoidCallback onLoadOlder;

  const ChatHistoryList({
    super.key,
    this.controller,
    required this.messageCount,
    required this.messageBuilder,
    this.pending,
    required this.hasOlder,
    required this.loadingOlder,
    required this.olderLoadFailed,
    required this.onLoadOlder,
  });

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        !hasOlder ||
        loadingOlder ||
        olderLoadFailed) {
      return false;
    }
    final delta = switch (notification) {
      ScrollUpdateNotification() => notification.scrollDelta ?? 0,
      OverscrollNotification() => notification.overscroll,
      _ => 0,
    };
    if (delta > 0 && notification.metrics.extentAfter <= 80) onLoadOlder();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final offset = pending == null ? 0 : 1;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        controller: controller,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: offset + messageCount + (hasOlder ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < offset) return pending!;
          final messageIndex = messageCount - 1 - (index - offset);
          if (messageIndex >= 0) return messageBuilder(context, messageIndex);
          return Center(
            child: loadingOlder
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Đang tải tin nhắn cũ',
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: onLoadOlder,
                    child: Text(
                      olderLoadFailed
                          ? 'Thử tải lại tin nhắn cũ'
                          : 'Tải tin nhắn cũ hơn',
                    ),
                  ),
          );
        },
      ),
    );
  }
}
