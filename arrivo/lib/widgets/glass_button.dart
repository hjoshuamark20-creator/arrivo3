import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Secondary pill button with a frosted glass fill.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Text and icon color. Defaults to the theme text color.
  final Color? color;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = color ?? Theme.of(context).textTheme.bodyMedium?.color;
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: GlassCard(
            radius: height / 2,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: onPressed,
                child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Text(label,
                            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
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
