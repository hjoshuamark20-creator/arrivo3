import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/ui_helpers.dart';
import '../models/app_settings.dart';
import '../providers/providers.dart';
import '../services/geo_utils.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/glass_group.dart';
import '../widgets/glass_page.dart';
import '../widgets/glass_segmented.dart';
import '../widgets/glass_switch.dart';
import '../widgets/glass_tab_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _soundLabel(AppSettings s, WidgetRef ref) {
    switch (s.soundMode) {
      case SoundMode.phoneDefault:
        return 'Phone default';
      case SoundMode.ringtone:
        switch (s.soundPath) {
          case 'ringtone':
            return 'Phone ringtone';
          case 'notification':
            return 'Phone notification tone';
          default:
            return 'Phone alarm tone';
        }
      case SoundMode.file:
        final path = s.soundPath;
        if (path == null || path == 'alarm' || path == 'ringtone' || path == 'notification') {
          return 'Audio file (none chosen)';
        }
        return ref.read(soundFileStoreProvider).displayName(path);
    }
  }

  Future<void> _pickSound(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassCard(
            radius: 32,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassRow(
                  label: 'Phone default alarm',
                  onTap: () {
                    notifier.update((s) => s.copyWith(soundMode: SoundMode.phoneDefault));
                    Navigator.of(sheetContext).pop();
                  },
                ),
                GlassRow(
                  label: 'Phone ringtone',
                  onTap: () {
                    notifier.update(
                        (s) => s.copyWith(soundMode: SoundMode.ringtone, soundPath: 'ringtone'));
                    Navigator.of(sheetContext).pop();
                  },
                ),
                GlassRow(
                  label: 'Phone notification tone',
                  onTap: () {
                    notifier.update((s) =>
                        s.copyWith(soundMode: SoundMode.ringtone, soundPath: 'notification'));
                    Navigator.of(sheetContext).pop();
                  },
                ),
                GlassRow(
                  label: 'Choose an audio file...',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final path = await ref.read(soundFileStoreProvider).pickAndStore();
                    if (path != null) {
                      await notifier
                          .update((s) => s.copyWith(soundMode: SoundMode.file, soundPath: path));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final ok = await showGlassConfirm(
      context,
      title: 'Log out?',
      message: 'This stops any active trip and signs you out of this phone.',
      confirmLabel: 'Log out',
      cancelLabel: 'Stay logged in',
      destructive: true,
    );
    if (ok) await ref.read(authControllerProvider.notifier).logOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final text = Theme.of(context).textTheme;

    return GlassPage(
      title: 'Settings',
      child: ListView(
        padding: EdgeInsets.only(bottom: tabBarClearance(context)),
        children: [
          GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                  child: Text(
                    user?.initials ?? '?',
                    style: text.titleMedium?.copyWith(color: AppColors.navy, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Guest',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                      Text(user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: mutedColor(context))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassGroup(
            children: [
              GlassRow(
                label: 'Alarm sound',
                subtitle: _soundLabel(settings, ref),
                onTap: () => _pickSound(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Default radius', style: text.bodyLarge)),
                        Text(formatDistance(settings.defaultRadius, settings.units),
                            style: text.titleMedium),
                      ],
                    ),
                    Slider(
                      value: settings.defaultRadius,
                      min: AppConstants.minRadiusMeters,
                      max: AppConstants.maxRadiusMeters,
                      divisions: 36,
                      label: formatDistance(settings.defaultRadius, settings.units),
                      onChanged: (v) => notifier.update((s) => s.copyWith(defaultRadius: v)),
                    ),
                  ],
                ),
              ),
              GlassRow(
                label: 'Vibration',
                trailing: GlassSwitch(
                  value: settings.vibration,
                  semanticLabel: 'Vibration',
                  onChanged: (v) => notifier.update((s) => s.copyWith(vibration: v)),
                ),
              ),
              GlassRow(
                label: 'Distance units',
                trailing: SizedBox(
                  width: 150,
                  child: GlassSegmented<DistanceUnit>(
                    options: const {DistanceUnit.km: 'km', DistanceUnit.mi: 'mi'},
                    value: settings.units,
                    onChanged: (u) => notifier.update((s) => s.copyWith(units: u)),
                  ),
                ),
              ),
              GlassRow(
                label: 'Dark mode',
                trailing: GlassSwitch(
                  value: settings.darkMode,
                  semanticLabel: 'Dark mode',
                  knobIcon: settings.darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  onChanged: (v) => notifier.update((s) => s.copyWith(darkMode: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassGroup(
            children: [
              GlassRow(
                label: 'Battery optimization tips',
                subtitle: 'Keep the alarm working with the screen off',
                onTap: () => context.push('/battery-tips'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassButton(
            label: 'Log out',
            icon: Icons.logout_rounded,
            color: Theme.of(context).colorScheme.error,
            onPressed: () => _logOut(context, ref),
          ),
        ],
      ),
    );
  }
}
