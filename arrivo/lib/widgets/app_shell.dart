import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'glass_background.dart';
import 'glass_tab_bar.dart';

/// Wraps the three tab screens (Map, Saved, Settings) and floats the glass tab bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _paths = ['/home', '/saved', '/settings'];

  int get _index {
    if (location.startsWith('/saved')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassBackground.baseColor(context, GlassBackdrop.theme),
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: GlassTabBar(
              index: _index,
              onChanged: (i) {
                if (i != _index) context.go(_paths[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
