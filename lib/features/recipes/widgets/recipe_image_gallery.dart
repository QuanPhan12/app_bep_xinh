import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Giữ trang ảnh theo bài; nút chuyển ảnh hỗ trợ cả thiết bị không có thao tác vuốt.
class RecipeImageGallery extends StatefulWidget {
  const RecipeImageGallery({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 4 / 3,
    this.useDots = false,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double aspectRatio;
  final bool useDots;

  @override
  State<RecipeImageGallery> createState() => _RecipeImageGalleryState();
}

class _RecipeImageGalleryState extends State<RecipeImageGallery> {
  final _controller = PageController();
  var _index = 0;

  @override
  void didUpdateWidget(RecipeImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.itemCount) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    if (widget.useDots && widget.itemCount > 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.itemCount,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: widget.itemBuilder,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.itemCount; index++)
                Semantics(
                  key: ValueKey('recipe_photo_dot_$index'),
                  label: 'Ảnh ${index + 1}',
                  button: true,
                  selected: index == _index,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 32,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: widget.itemCount == 1
          ? widget.itemBuilder(context, 0)
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: widget.itemCount,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: widget.itemBuilder,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Semantics(
                    liveRegion: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Ảnh ${_index + 1}/${widget.itemCount}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final next in [false, true])
                  if (next ? _index < widget.itemCount - 1 : _index > 0)
                    Align(
                      alignment: next
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: IconButton.filledTonal(
                          tooltip: next ? 'Ảnh tiếp theo' : 'Ảnh trước',
                          onPressed: () => _controller.animateToPage(
                            _index + (next ? 1 : -1),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          ),
                          icon: Icon(
                            next
                                ? PhosphorIconsBold.caretRight
                                : PhosphorIconsBold.caretLeft,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}
