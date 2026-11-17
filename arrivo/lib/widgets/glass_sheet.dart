import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'glass_card.dart';

/// Floating bottom sheet: glass card with a drag handle. The [child] sits in a
/// Flexible, so pass a scroll view when the content may be taller than the space.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 36,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.navy.withAlpha(64),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(child: child),
        ],
      ),
    );
  }
}
