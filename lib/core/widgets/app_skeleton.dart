import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import 'app_card.dart';

/// Một animation cho cả bố cục, không tạo ticker trên mỗi ô skeleton.
class AppSkeleton extends StatefulWidget {
  final Widget child;
  const AppSkeleton({super.key, required this.child});
  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _enabled = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  void _sync() {
    if (_enabled && _foreground) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang tải',
    liveRegion: true,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: !_enabled
              ? widget.child
              : AnimatedBuilder(
                  animation: _controller,
                  child: widget.child,
                  builder: (context, child) => ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) =>
                        LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: .7),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [.1, .5, .9],
                        ).createShader(
                          Rect.fromLTWH(
                            rect.left +
                                rect.width * (_controller.value * 4 - 2),
                            rect.top,
                            rect.width * 1.5,
                            rect.height,
                          ),
                        ),
                    child: child,
                  ),
                ),
        ),
      ),
    ),
  );
}

class SkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Các khối có thể ghép vào skeleton riêng của mỗi màn.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FractionallySizedBox(widthFactor: .7, child: SkeletonBlock(height: 14)),
      SizedBox(height: 10),
      SkeletonBlock(height: 10),
      SizedBox(height: 7),
      FractionallySizedBox(widthFactor: .5, child: SkeletonBlock(height: 10)),
    ],
  );
}

class SkeletonListRows extends StatelessWidget {
  final int count;
  const SkeletonListRows({super.key, this.count = 4});
  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (_, _) => const Row(
        children: [
          SkeletonBlock(height: 42, width: 42, radius: 14),
          SizedBox(width: 12),
          Expanded(child: SkeletonLines()),
        ],
      ),
    ),
  );
}

class AppContentSkeleton extends StatelessWidget {
  const AppContentSkeleton({super.key});
  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SkeletonBlock(height: 48, radius: 14),
          const SizedBox(height: 20),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: AppCard(
                padding: EdgeInsets.all(16),
                child: SkeletonLines(),
              ),
            ),
        ],
      ),
    ),
  );
}
