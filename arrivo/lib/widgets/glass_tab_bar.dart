import 'package:flutter/material.dart';

import '../core/ui_helpers.dart';
import 'glass_card.dart';

/// Floating glass pill with the three main tabs.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.map_rounded, 'Map'),
    (Icons.bookmark_rounded, 'Saved'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkTheme(context);
    final active = Theme.of(context).colorScheme.primary;
    return GlassCard(
      radius: 32,
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: _items[i].$2,
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: i == index
                              ? (isDark ? const Color(0x33FFFFFF) : const Color(0xCCFFFFFF))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_items[i].$1,
                                size: 22, color: i == index ? active : mutedColor(context)),
                            Text(
                              _items[i].$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: i == index ? active : mutedColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Space to leave at the bottom of tab screens so content clears the floating tab bar.
double tabBarClearance(BuildContext context) => MediaQuery.of(context).padding.bottom + 24 + 64 + 16;
