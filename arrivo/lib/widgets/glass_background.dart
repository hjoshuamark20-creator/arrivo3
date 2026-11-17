import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/constants.dart';

enum GlassBackdrop { theme, deepNavy, amber }

/// The shared backdrop of every screen: a solid base color with two soft, blurred
/// color glows. Glass panels on top of it get the same frosted look everywhere.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child, this.backdrop = GlassBackdrop.theme});

  final Widget child;
  final GlassBackdrop backdrop;

  static Color baseColor(BuildContext context, GlassBackdrop backdrop) {
    switch (backdrop) {
      case GlassBackdrop.deepNavy:
        return AppColors.deepNavy;
      case GlassBackdrop.amber:
        return AppColors.amber;
      case GlassBackdrop.theme:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.deepNavy
            : AppColors.lightBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color glowOne;
    final Color glowTwo;
    switch (backdrop) {
      case GlassBackdrop.amber:
        glowOne = const Color(0x73FFFFFF);
        glowTwo = const Color(0x59EF4444);
      case GlassBackdrop.deepNavy:
        glowOne = const Color(0x7314B8A6);
        glowTwo = const Color(0x663B82F6);
      case GlassBackdrop.theme:
        glowOne = isDark ? const Color(0x7314B8A6) : const Color(0x6614B8A6);
        glowTwo = isDark ? const Color(0x663B82F6) : const Color(0x4D3B82F6);
    }
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: baseColor(context, backdrop)),
          Positioned(top: -90, right: -90, child: _Glow(color: glowOne)),
          Positioned(bottom: -100, left: -110, child: _Glow(color: glowTwo)),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
