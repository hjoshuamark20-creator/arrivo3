import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Pill button. Default is teal with navy bold text and a teal glow.
/// Pass [color] and [textColor] for other variants (for example the navy Dismiss button).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.height = 56,
    this.color = AppColors.teal,
    this.textColor = AppColors.navy,
    this.glow = const Color(0x6614B8A6),
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double height;
  final Color color;
  final Color textColor;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
              border: Border.all(color: const Color(0x99FFFFFF)),
              boxShadow: [BoxShadow(color: glow, blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: enabled ? onPressed : null,
                child: Center(
                  child: Text(
                    busy ? 'Please wait...' : label,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
