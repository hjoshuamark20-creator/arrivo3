import 'package:flutter/material.dart';

import '../core/ui_helpers.dart';

/// Three rings that expand and fade around [child] (splash radar, alarm pulse).
class PulseRings extends StatefulWidget {
  const PulseRings({
    super.key,
    required this.color,
    required this.size,
    required this.child,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Color color;
  final double size;
  final Widget child;
  final Duration duration;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = (_controller.value + i / 3) % 1.0;
                return Opacity(
                  opacity: (1 - t) * 0.8,
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * t,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.color, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
          widget.child,
        ],
      ),
    );
  }
}

/// The blue "you are here" dot with a pulse.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: (1 - _controller.value) * 0.5,
              child: Transform.scale(
                scale: 0.5 + _controller.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder block shown while data loads (used instead of spinners).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 20, this.width, this.radius = 16});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = isDarkTheme(context) ? Colors.white : const Color(0xFF0F172A);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: base.withAlpha((25 + 35 * _controller.value).round()),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
