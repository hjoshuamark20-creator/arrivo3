import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';

/// Custom glass switch (use this instead of Checkbox or the default Switch).
/// 62 x 36 frosted track, 30 px knob that slides with a 200 ms spring-like curve.
class GlassSwitch extends StatelessWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.knobIcon,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  /// Optional small icon shown on the knob (for example a sun for Dark mode).
  final IconData? knobIcon;

  void _toggle() {
    HapticFeedback.selectionClick();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    final track = value ? AppColors.teal.withAlpha(153) : AppColors.navy.withAlpha(51);
    return Semantics(
      label: semanticLabel,
      toggled: value,
      onTap: _toggle,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 62, minHeight: 48),
            child: Center(
              widthFactor: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorderLight),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xF2FFFFFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x590F172A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: knobIcon == null
                            ? null
                            : Icon(knobIcon, size: 16, color: AppColors.navy),
                      ),
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
