import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'glass_card.dart';

class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.showDot = false});
  final String label;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
