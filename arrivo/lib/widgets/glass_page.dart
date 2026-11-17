import 'package:flutter/material.dart';

import 'glass_background.dart';
import 'glass_card.dart';

/// Background + safe area + optional title and back button. No Scaffold, so it can
/// live inside the tab shell. Use [GlassScaffold] for full-screen pages.
class GlassPage extends StatelessWidget {
  const GlassPage({
    super.key,
    required this.child,
    this.title,
    this.onBack,
    this.backdrop = GlassBackdrop.theme,
    this.padding = const EdgeInsets.fromLTRB(18, 8, 18, 0),
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final GlassBackdrop backdrop;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      backdrop: backdrop,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || onBack != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (onBack != null) ...[
                        GlassBackButton(onPressed: onBack!),
                        const SizedBox(width: 12),
                      ],
                      if (title != null)
                        Expanded(
                          child: Text(title!, style: Theme.of(context).textTheme.headlineMedium),
                        ),
                    ],
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.child,
    this.title,
    this.onBack,
    this.backdrop = GlassBackdrop.theme,
    this.padding = const EdgeInsets.fromLTRB(18, 8, 18, 0),
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final GlassBackdrop backdrop;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassBackground.baseColor(context, backdrop),
      body: GlassPage(
        title: title,
        onBack: onBack,
        backdrop: backdrop,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Round glass back button (48 x 48 touch target).
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: 'Back',
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
    );
  }
}
