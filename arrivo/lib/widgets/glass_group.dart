import 'package:flutter/material.dart';

import '../core/ui_helpers.dart';
import 'glass_card.dart';

/// A glass card holding rows separated by thin dividers (Settings groups).
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, thickness: 1, color: glassBorder(context));
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) divider,
            children[i],
          ],
        ],
      ),
    );
  }
}

class GlassRow extends StatelessWidget {
  const GlassRow({super.key, required this.label, this.subtitle, this.trailing, this.onTap});

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: subtitle == null ? label : '$label, $subtitle',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: text.bodySmall?.copyWith(color: mutedColor(context))),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null)
                  Icon(Icons.chevron_right_rounded, color: mutedColor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
