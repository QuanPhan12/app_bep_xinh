import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_avatar.dart';
import 'ai_chat_entry.dart';

/// Chỉ nằm trong body của shell; Scaffold dành riêng vùng bottom navigation.
class AiChatFloatingLayer extends StatefulWidget {
  final Widget child;
  const AiChatFloatingLayer({super.key, required this.child});
  @override
  State<AiChatFloatingLayer> createState() => _AiChatFloatingLayerState();
}

class _AiChatFloatingLayerState extends State<AiChatFloatingLayer> {
  // Tọa độ tương đối giữ vị trí khi xoay máy hoặc đổi kích thước/bàn phím.
  Offset anchor = const Offset(1, 1);
  bool opening = false;
  void open() {
    if (opening) return;
    opening = true;
    context.push('/messages/ai').whenComplete(() {
      opening = false;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const size = 56.0, margin = 12.0;
      final safe = MediaQuery.paddingOf(context);
      final top = safe.top + margin, bottom = safe.bottom + margin;
      if (constraints.maxWidth < size + margin * 2 ||
          constraints.maxHeight < size + top + bottom) {
        return widget.child;
      }
      final travelX = constraints.maxWidth - size - margin * 2;
      final travelY = constraints.maxHeight - size - top - bottom;
      final colors = Theme.of(context).colorScheme;
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned(
            left: margin + anchor.dx * travelX,
            top: top + anchor.dy * travelY,
            width: size,
            height: size,
            child: GestureDetector(
              key: const ValueKey('ai_floating_drag_handle'),
              onPanUpdate: (details) => setState(() {
                anchor = Offset(
                  travelX == 0
                      ? 0
                      : (anchor.dx + details.delta.dx / travelX).clamp(
                          0.0,
                          1.0,
                        ),
                  travelY == 0
                      ? 0
                      : (anchor.dy + details.delta.dy / travelY).clamp(
                          0.0,
                          1.0,
                        ),
                );
              }),
              child: Tooltip(
                message: 'Chat Bếp Xinh AI · Kéo để di chuyển',
                child: Material(
                  elevation: 4,
                  shadowColor: colors.shadow.withValues(alpha: .25),
                  color: colors.surface,
                  shape: CircleBorder(
                    side: BorderSide(color: colors.primary, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('ai_floating_open'),
                    onTap: open,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: AppAvatar(
                        name: 'Bếp Xinh AI',
                        assetPath: aiAvatarAsset,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
