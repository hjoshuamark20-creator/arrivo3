import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/user_account.dart';
import '../providers/providers.dart';
import '../widgets/animated_bits.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_page.dart';
import '../widgets/logo_tile.dart';

/// Animated loading screen. While it plays it restores the session and any active trip,
/// checks permissions, and then routes to Onboarding, Log in, Trip, or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration:
        AppConstants.splashMinDuration + const Duration(milliseconds: 400),
  )..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final minimum = Future<void>.delayed(AppConstants.splashMinDuration);

    UserAccount? user;
    try {
      user = await ref.read(authControllerProvider.future);
    } catch (_) {}
    if (!mounted) return;

    if (user != null) {
      try {
        await ref.read(tripControllerProvider.notifier).restore();
        if (ref.read(launchedFromAlarmProvider)) {
          ref.read(tripControllerProvider.notifier).markRinging();
        }
      } catch (_) {}
    }
    if (!mounted) return;

    try {
      await ref.read(permissionServiceProvider).checkLocation();
    } catch (_) {}

    await minimum;
    if (!mounted) return;

    final onboarded = ref.read(onboardingDoneProvider);
    final signedIn = ref.read(authControllerProvider).valueOrNull != null;
    if (!onboarded) {
      context.go('/onboarding');
    } else if (!signedIn) {
      context.go('/login');
    } else {
      context.go(ref.read(tripControllerProvider).active ? '/trip' : '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) => GlassScaffold(
          backdrop: GlassBackdrop.deepNavy,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulseRings(
                  color: AppColors.tealLight,
                  size: 260,
                  child: LogoTile(size: 210),
                ),
                const SizedBox(height: 20),
                Text(
                  'Arrivo',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 38),
                ),
                const SizedBox(height: 6),
                Text(
                  'Never miss your stop',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.slateLight),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 220,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) => LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: const Color(0x26FFFFFF),
                      color: AppColors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Finding your location...',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.slateLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
