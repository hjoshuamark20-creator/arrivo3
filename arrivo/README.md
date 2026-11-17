# Arrivo - Never miss your stop

A geofence arrival alarm for commuters (jeep, bus, train). Log in, pick a stop on the
map, set how close you want to be, and Arrivo rings and vibrates when you get there,
even with the screen off.

## Set up

1. Create a Flutter project named `arrivo` (`flutter create arrivo`), or use this folder directly.
2. Copy these into the project, replacing what is there: `lib/`, `test/`, `pubspec.yaml`.
3. Replace `android/app/src/main/AndroidManifest.xml` with the one in this folder, and apply the
   changes in `android/GRADLE_NOTES.md` to `android/app/build.gradle` (minSdk 23 and desugaring).
4. iPhone only: add the keys in `ios/Runner/Info.plist.additions.xml` to `ios/Runner/Info.plist`.
5. Delete `test/widget_test.dart` if Flutter created it.
6. Run:

```
flutter pub get
flutter analyze
flutter test
flutter run            # with a real phone connected by USB
flutter build apk --release   # APK: build/app/outputs/flutter-apk/app-release.apk
```

Test on a real phone. GPS, background tracking, and the alarm do not work properly on emulators.

## Project structure

```
lib/
  main.dart                      app start, notifications, background service setup
  core/                          colors, theme, router (login redirects), permission flow, UI helpers
  models/                        user, place, trip, settings, tracking update, destination args
  services/
    auth_repository.dart         local accounts (salted SHA-256 hash in secure storage)
    geofence_engine.dart         distance filter, smoothing, when to ring, snooze
    tracking_service.dart        background service (keeps tracking with the screen off)
    alarm_player.dart            looping alarm sound + vibration
    notification_service.dart    full-screen alarm notification
    permission_service.dart      location, notification, battery permissions
    storage_services.dart        settings, SQLite places and trip history, active trip
    place_search_service.dart    OpenStreetMap search
  providers/providers.dart       Riverpod providers
  screens/                       splash, onboarding, login, sign up, home, set alarm,
                                 active trip, alarm, saved places, settings, battery tips
  widgets/                       the shared glass design system (see below)
test/                            auth, distance, and alarm trigger tests
```

## Glass design system (used by every screen)

- `GlassBackground`: solid base color with two blurred color glows (theme, deep navy, or amber).
- `GlassPage` / `GlassScaffold`: background, safe area, title, glass back button.
- `GlassCard`: frosted panel (blur, translucent fill, light border, soft shadow).
- `GlassSheet`, `GlassTabBar`, `GlassGroup` / `GlassRow`, `GlassSegmented`, `GlassChip`,
  `GlassTextField`, `GlassButton` (secondary), `PrimaryButton` (teal), `GlassSwitch`,
  `PlayButton`, and the `showGlassConfirm` dialog.
