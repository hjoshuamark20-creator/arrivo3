import 'package:flutter/material.dart';

/// Brand colors and glass surface colors (alpha values written as ARGB hex).
class AppColors {
  static const Color navy = Color(0xFF0F172A);
  static const Color deepNavy = Color(0xFF0B1220);
  static const Color teal = Color(0xFF14B8A6);
  static const Color darkTeal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFF5EEAD4);
  static const Color amber = Color(0xFFF59E0B);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color slate = Color(0xFF475569);
  static const Color slateLight = Color(0xFFCBD5E1);
  static const Color error = Color(0xFFB91C1C);
  static const Color lightBg = Color(0xFFDDEBF4);
  static const Color slateCard = Color(0xFF1E293B);

  // Glass surfaces
  static const glassLight = Color(0x8CFFFFFF); // white 55%
  static const glassBorderLight = Color(0xBFFFFFFF); // white 75%
  static const glassShadowLight = Color(0x2E0F172A); // navy 18%
  static const glassDark = Color(0x801E293B); // #1E293B 50%
  static const glassBorderDark = Color(0x33FFFFFF); // white 20%
  static const glassShadowDark = Color(0x59000000); // black 35%
}

class AppConstants {
  static const minRadiusMeters = 50.0;
  static const maxRadiusMeters = 2000.0;
  static const defaultRadiusMeters = 800.0;
  static const snoozeDuration = Duration(minutes: 2);
  static const splashMinDuration = Duration(seconds: 2);
  static const maxAcceptableAccuracyMeters = 100.0;

  // SharedPreferences keys
  static const prefsOnboardingDone = 'onboarding.done';
  static const prefsSettings = 'settings.json';
  static const prefsActiveTrip = 'trip.active';
}
