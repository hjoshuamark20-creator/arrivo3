import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/ui_helpers.dart';
import '../providers/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_page.dart';
import '../widgets/primary_button.dart';

/// Three slides shown on first launch. "Get Started" asks for the permissions.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _slides = [
    (
      Icons.directions_bus_rounded,
      'Never miss your stop',
      'Pick your stop and how close you want to be. Sleep, read, or scroll. Arrivo wakes you up on time.'
    ),
    (
      Icons.my_location_rounded,
      'Why location?',
      'Arrivo measures your distance to the stop. Allow location “all the time” so the alarm works even with the screen off.'
    ),
    (
      Icons.notifications_active_rounded,
      'Why notifications?',
      'The alarm appears as a full-screen alert over your lock screen, so you can’t sleep through your stop.'
    ),
  ];

  final PageController _pages = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _slides.length - 1) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish(askPermissions: true);
  }

  Future<void> _finish({required bool askPermissions}) async {
    setState(() => _busy = true);
    if (askPermissions) {
      final perms = ref.read(permissionServiceProvider);
      await perms.requestLocation();
      await perms.requestNotifications();
    }
    await ref.read(onboardingDoneProvider.notifier).complete();
    if (!mounted) return;
    final signedIn = ref.read(authControllerProvider).valueOrNull != null;
    context.go(signedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final last = _page == _slides.length - 1;
    return GlassScaffold(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : () => _finish(askPermissions: false),
              child: const Text('Skip'),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final slide in _slides)
                  Center(
                    child: GlassCard(
                      radius: 36,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withAlpha(64),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(slide.$1,
                                size: 44,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(slide.$2,
                              textAlign: TextAlign.center,
                              style: text.headlineMedium),
                          const SizedBox(height: 12),
                          Text(
                            slide.$3,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge
                                ?.copyWith(color: mutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.teal
                        : mutedColor(context).withAlpha(100),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
              label: last ? 'Get Started' : 'Next',
              busy: _busy,
              onPressed: _next),
          SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
