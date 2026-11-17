import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../services/geo_utils.dart';
import '../widgets/animated_bits.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_page.dart';
import '../widgets/primary_button.dart';

/// Full-screen amber alarm. Keeps the screen awake while it rings.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripControllerProvider);
    final settings = ref.watch(settingsProvider);
    final name = state.trip?.destinationName ?? 'Your stop';
    final update = state.update;
    final distanceText = (update != null && update.hasDistance)
        ? formatDistance(update.distanceMeters, settings.units)
        : 'very close';

    // The alarm is always light-themed (navy text on amber) so it is easy to read.
    return PopScope(
      canPop: false,
      child: Theme(
        data: AppTheme.light,
        child: Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            return GlassScaffold(
              backdrop: GlassBackdrop.amber,
              child: Column(
                children: [
                  const Spacer(),
                  const PulseRings(
                    color: Colors.white,
                    size: 260,
                    duration: Duration(milliseconds: 2000),
                    child: GlassCard(
                      radius: 52,
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: Icon(Icons.notifications_active_rounded,
                            size: 46, color: AppColors.navy),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'You’re almost there!',
                      textAlign: TextAlign.center,
                      style: text.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$name is $distanceText away',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(fontSize: 17),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Dismiss',
                    height: 60,
                    color: AppColors.navy,
                    textColor: AppColors.offWhite,
                    glow: const Color(0x590F172A),
                    onPressed: () => ref.read(tripControllerProvider.notifier).dismiss(),
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    label: 'Snooze 2 min',
                    onPressed: () => ref.read(tripControllerProvider.notifier).snooze(),
                  ),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
