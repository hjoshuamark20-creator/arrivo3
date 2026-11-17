import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ui_helpers.dart';
import '../providers/providers.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_page.dart';
import '../widgets/primary_button.dart';

/// Some phone brands stop background apps to save battery. This screen explains how
/// to let Arrivo keep tracking so the alarm still rings with the screen off.
class BatteryTipsScreen extends ConsumerWidget {
  const BatteryTipsScreen({super.key});

  static const _tips = [
    ('Samsung', 'Settings > Battery > Background usage limits > Never sleeping apps > add Arrivo.'),
    ('Xiaomi / Redmi / Poco', 'Settings > Apps > Manage apps > Arrivo > turn on Autostart, then set Battery saver to No restrictions.'),
    ('Oppo / Realme / Vivo', 'Settings > Battery > App battery management > Arrivo > allow background activity, and turn on Auto-start.'),
    ('Other phones', 'Settings > Apps > Arrivo > Battery > choose Unrestricted.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final perms = ref.read(permissionServiceProvider);
    return GlassScaffold(
      title: 'Battery tips',
      onBack: () => context.pop(),
      child: ListView(
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.of(context).padding.bottom),
        children: [
          GlassCard(
            radius: 28,
            child: Text(
              'To ring with the screen off, Arrivo has to keep tracking your location in the background. '
              'Many phones stop background apps to save battery, so allow Arrivo to run freely.',
              style: text.bodyLarge,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Allow background running',
            onPressed: () => perms.requestIgnoreBatteryOptimizations(),
          ),
          const SizedBox(height: 10),
          GlassButton(
            label: 'Open app settings',
            icon: Icons.settings_rounded,
            onPressed: () => perms.openAppSettingsPage(),
          ),
          const SizedBox(height: 18),
          Text('Steps by phone brand', style: text.titleMedium),
          const SizedBox(height: 6),
          Text('Menu names can differ a little between versions.',
              style: text.bodySmall?.copyWith(color: mutedColor(context))),
          const SizedBox(height: 12),
          for (final tip in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.$1, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(tip.$2, style: text.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
