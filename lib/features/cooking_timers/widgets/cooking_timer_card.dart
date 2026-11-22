import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/cooking_timer_service.dart';

class CookingTimerCard extends StatelessWidget {
  final CookingTimer timer;
  final DateTime now;
  final bool busy;
  final VoidCallback onToggle, onRemove;
  const CookingTimerCard({
    super.key,
    required this.timer,
    required this.now,
    required this.onToggle,
    required this.onRemove,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final remaining = timer.remaining(now);
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final finished = seconds == 0;
    final accent = colors.primary;
    final status = finished
        ? 'Đã hết giờ'
        : timer.paused
        ? 'Đang tạm dừng'
        : 'Đang đếm ngược';
    final time = seconds >= 3600
        ? '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    // Hẹn giờ cũ chưa lưu tổng thời lượng chỉ hiện nền vòng, không suy diễn tiến độ.
    final progress = timer.durationMilliseconds > 0
        ? (remaining.inMilliseconds / timer.durationMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(
          color: finished
              ? accent.withValues(alpha: .4)
              : colors.outlineVariant.withValues(alpha: .6),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  PhosphorIconsRegular.timer,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  timer.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter = (184 * MediaQuery.textScalerOf(context).scale(1))
                  .clamp(184.0, 260.0)
                  .clamp(0.0, constraints.maxWidth);
              return Center(
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: CircularProgressIndicator(
                            value: finished ? 1 : progress,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: colors.outlineVariant.withValues(
                              alpha: .45,
                            ),
                            color: timer.paused
                                ? colors.onSurfaceVariant.withValues(alpha: .45)
                                : accent,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              finished
                                  ? PhosphorIconsRegular.check
                                  : timer.paused
                                  ? PhosphorIconsRegular.pause
                                  : PhosphorIconsRegular.cookingPot,
                              size: 24,
                              color: accent,
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                time,
                                key: ValueKey('active_timer_${timer.id}'),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: seconds >= 3600 ? 32 : 42,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              finished ? 'Hoàn thành' : 'Còn lại',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                status,
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : finished
                      ? onRemove
                      : onToggle,
                  icon: Icon(
                    finished
                        ? PhosphorIconsRegular.check
                        : timer.paused
                        ? PhosphorIconsRegular.play
                        : PhosphorIconsRegular.pause,
                    size: 18,
                  ),
                  label: Text(
                    finished
                        ? 'Xong'
                        : timer.paused
                        ? 'Tiếp tục'
                        : 'Tạm dừng',
                  ),
                ),
              ),
              if (!finished) const SizedBox(width: 10),
              if (!finished)
                IconButton.filledTonal(
                  onPressed: busy ? null : onRemove,
                  tooltip: 'Xóa hẹn giờ',
                  icon: const Icon(PhosphorIconsRegular.trash, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
