import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/destination_args.dart';
import '../providers/providers.dart';
import '../screens/active_trip_screen.dart';
import '../screens/alarm_screen.dart';
import '../screens/battery_tips_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/saved_places_screen.dart';
import '../screens/set_alarm_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/app_shell.dart';

const _authPaths = {'/login', '/signup', '/onboarding'};

/// Decides where the user may be, based on login state and the active trip.
String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  if (location == '/splash') return null; // the splash screen decides where to go next

  final auth = ref.read(authControllerProvider);
  if (auth.isLoading) return null;

  final signedIn = auth.valueOrNull != null;
  final trip = ref.read(tripControllerProvider);

  if (!signedIn) {
    return _authPaths.contains(location) ? null : '/login';
  }
  if (_authPaths.contains(location)) return trip.active ? '/trip' : '/home';
  if (trip.ringing && location != '/alarm') return '/alarm';
  if (!trip.ringing && location == '/alarm') return trip.active ? '/trip' : '/home';
  if (!trip.active && location == '/trip') return '/home';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect when the login state or the trip state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (previous, next) => refresh.value++);
  ref.listen<TripState>(tripControllerProvider, (previous, next) {
    if (previous?.active != next.active || previous?.ringing != next.ringing) {
      refresh.value++;
    }
  });
  ref.onDispose(refresh.dispose);

  Page<void> tab(GoRouterState state, Widget child) =>
      NoTransitionPage<void>(key: state.pageKey, child: child);

  Page<void> slideUp(GoRouterState state, Widget child) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      );

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (context, state) => tab(state, const HomeScreen())),
          GoRoute(
              path: '/saved',
              pageBuilder: (context, state) => tab(state, const SavedPlacesScreen())),
          GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => tab(state, const SettingsScreen())),
        ],
      ),
      GoRoute(
        path: '/set-alarm',
        redirect: (context, state) => state.extra is DestinationArgs ? null : '/home',
        pageBuilder: (context, state) =>
            slideUp(state, SetAlarmScreen(args: state.extra! as DestinationArgs)),
      ),
      GoRoute(path: '/trip', builder: (context, state) => const ActiveTripScreen()),
      GoRoute(
        path: '/alarm',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const AlarmScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(path: '/battery-tips', builder: (context, state) => const BatteryTipsScreen()),
    ],
  );
});
