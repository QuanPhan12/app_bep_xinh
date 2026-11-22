import 'package:app_bep_xinh/sollume/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Hai cung tròn xoay của flutter_spinkit, dùng chung ở mọi nơi trong app.
/// Chỉ nhận cấu hình hiển thị; trạng thái tải vẫn thuộc Cubit/Bloc bên gọi.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.semanticsLabel = 'Đang xử lý',
  }) : assert(size > 0 && size < double.infinity);

  final double size;
  final Color? color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.primary;
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    final lineWidth = (size * .09).clamp(0.0, 3.0);

    return Semantics(
      label: context.uiLabel(semanticsLabel),
      child: SizedBox.square(
        dimension: size,
        child: TickerMode(
          // Thư viện sở hữu controller; muted ticker không lên lịch frame mới.
          enabled: animate,
          child: Padding(
            // Nét được vẽ giữa đường biên: chừa nửa nét để không tràn khỏi nút.
            padding: EdgeInsets.all(lineWidth / 2),
            child: SpinKitFadingCircle(
              color: foreground,
              size: size - lineWidth,
              // lineWidth: lineWidth,
              duration: const Duration(milliseconds: 1000),
            ),
          ),
        ),
      ),
    );
  }
}
