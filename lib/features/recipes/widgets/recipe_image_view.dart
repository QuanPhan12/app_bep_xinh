import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/recipe_image.dart';

class RecipeImageView extends StatelessWidget {
  final RecipeImage image;
  final double aspectRatio;
  const RecipeImageView({
    super.key,
    required this.image,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cacheWidth =
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 1600);
          Widget error(BuildContext _, Object _, StackTrace? _) =>
              ColoredBox(
                color: context.colors.surfaceVariant,
                child: Center(
                  child: Icon(
                    PhosphorIconsRegular.imageBroken,
                    color: context.colors.textTertiary,
                  ),
                ),
              );
          final bytes = image.bytes;
          if (image.url != null) {
            return Image.network(
              image.url!,
              fit: BoxFit.cover,
              semanticLabel: image.name,
              cacheWidth: cacheWidth,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: error,
            );
          }
          if (bytes != null) {
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              semanticLabel: image.name,
              cacheWidth: cacheWidth,
              errorBuilder: (context, exception, stack) => kIsWeb
                  ? _BrowserImagePreview(image: image, onError: error)
                  : error(context, exception, stack),
            );
          }
          return Image.asset(
            image.assetPath!,
            fit: BoxFit.cover,
            semanticLabel: image.name,
            cacheWidth: cacheWidth,
            errorBuilder: error,
          );
        },
      ),
    ),
  );
}

/// Dùng decoder của trình duyệt nếu CanvasKit không vẽ được ảnh đã chọn.
/// Data URL chỉ tồn tại trong bộ nhớ, không upload ảnh khi xem trước.
class _BrowserImagePreview extends StatefulWidget {
  final RecipeImage image;
  final ImageErrorWidgetBuilder onError;
  const _BrowserImagePreview({required this.image, required this.onError});

  @override
  State<_BrowserImagePreview> createState() => _BrowserImagePreviewState();
}

class _BrowserImagePreviewState extends State<_BrowserImagePreview> {
  late String _source = _dataUrl();

  String _dataUrl() => Uri.dataFromBytes(
    widget.image.bytes!,
    mimeType: 'application/octet-stream',
  ).toString();

  @override
  void didUpdateWidget(covariant _BrowserImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image.bytes, widget.image.bytes)) {
      _source = _dataUrl();
    }
  }

  @override
  Widget build(BuildContext context) => Image.network(
    _source,
    fit: BoxFit.cover,
    semanticLabel: widget.image.name,
    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
    errorBuilder: widget.onError,
  );
}
