import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/place.dart';
import '../models/tracking_update.dart';
import '../models/trip.dart';
import '../models/user_account.dart';
import '../services/alarm_player.dart';
import '../services/auth_repository.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/place_search_service.dart';
import '../services/sound_file_store.dart';
import '../services/storage_services.dart';
import '../services/tracking_service.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Infrastructure (override sharedPreferencesProvider in main with the real instance)
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);

final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)));

final activeTripStoreProvider =
    Provider((ref) => ActiveTripStore(ref.watch(sharedPreferencesProvider)));

final placeRepositoryProvider = Provider((ref) => PlaceRepository(AppDatabase.instance));
final tripRepositoryProvider = Provider((ref) => TripRepository(AppDatabase.instance));

final permissionServiceProvider = Provider((ref) => PermissionService());
final locationServiceProvider = Provider((ref) => LocationService());
final placeSearchServiceProvider = Provider((ref) => PlaceSearchService());
final soundFileStoreProvider = Provider((ref) => SoundFileStore());
final notificationServiceProvider = Provider((ref) => NotificationService());
final trackingBridgeProvider = Provider((ref) => TrackingBridge());

/// Live position for the Home map (the trip itself is tracked by the background service).
final currentPositionProvider = StreamProvider.autoDispose<Position>(
  (ref) => ref.watch(locationServiceProvider).watch(),
);

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secretStoreProvider),
  ),
);

/// Null = logged out. Errors from sign up and log in are thrown as [AuthException]
/// so the form can show them; they do not change the provider state.
class AuthController extends AsyncNotifier<UserAccount?> {
  @override
  Future<UserAccount?> build() => ref.read(authRepositoryProvider).currentUser();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signUp(name: name, email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> logIn({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).logIn(email: email, password: password);
    state = AsyncData(user);
  }

  /// Stops any active trip and the background service, then clears the session.
  Future<void> logOut() async {
    await ref.read(tripControllerProvider.notifier).cancelIfActive();
    await ref.read(authRepositoryProvider).logOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserAccount?>(AuthController.new);

// ---------------------------------------------------------------------------
// Settings and onboarding
// ---------------------------------------------------------------------------

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).onboardingDone;

  Future<void> complete() async {
    await ref.read(settingsRepositoryProvider).setOnboardingDone();
    state = true;
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

// ---------------------------------------------------------------------------
// Saved places and trip history
// ---------------------------------------------------------------------------

class PlacesController extends AsyncNotifier<List<Place>> {
  @override
  Future<List<Place>> build() => ref.read(placeRepositoryProvider).list();

  Future<void> add({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final repo = ref.read(placeRepositoryProvider);
    await repo.save(Place(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'My stop' : name.trim(),
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      createdAt: DateTime.now(),
    ));
    state = AsyncData(await repo.list());
  }

  Future<void> remove(String id) async {
    final repo = ref.read(placeRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.list());
  }
}

final placesProvider = AsyncNotifierProvider<PlacesController, List<Place>>(
  PlacesController.new,
);

final tripHistoryProvider = FutureProvider.autoDispose<List<Trip>>(
  (ref) => ref.watch(tripRepositoryProvider).recent(),
);

// ---------------------------------------------------------------------------
// Active trip (talks to the background service)
// ---------------------------------------------------------------------------

class TripState {
  const TripState({this.trip, this.update, this.ringing = false, this.error});

  final Trip? trip;
  final TrackingUpdate? update;
  final bool ringing;
  final String? error;

  bool get active => trip != null;

  TripState copyWith({
    Trip? trip,
    TrackingUpdate? update,
    bool? ringing,
    String? error,
    bool clearError = false,
  }) =>
      TripState(
        trip: trip ?? this.trip,
        update: update ?? this.update,
        ringing: ringing ?? this.ringing,
        error: clearError ? null : (error ?? this.error),
      );
}

class TripController extends Notifier<TripState> {
  StreamSubscription<TrackingEvent>? _subscription;

  TrackingBridge get _bridge => ref.read(trackingBridgeProvider);

  @override
  TripState build() {
    _subscription = _bridge.events.listen(_onEvent);
    ref.onDispose(() => _subscription?.cancel());
    return const TripState();
  }

  void _onEvent(TrackingEvent event) {
    switch (event.type) {
      case TrackingEventType.update:
        state = state.copyWith(update: event.update, clearError: true);
      case TrackingEventType.ring:
        state = state.copyWith(ringing: true);
      case TrackingEventType.snoozed:
        state = state.copyWith(ringing: false);
      case TrackingEventType.ended:
        state = const TripState();
      case TrackingEventType.error:
        state = state.copyWith(error: event.message);
    }
  }

  /// Saves the trip, then starts the background service which reads it.
  Future<void> start({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final settings = ref.read(settingsProvider);
    final trip = Trip(
      id: _uuid.v4(),
      destinationName: name.trim().isEmpty ? 'My stop' : name.trim(),
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      startedAt: DateTime.now(),
    );
    await ref
        .read(activeTripStoreProvider)
        .save(ActiveTripSnapshot(trip: trip, settings: settings));
    await _bridge.start();
    state = TripState(trip: trip);
  }

  /// Call at app start: if a trip was running when the app was killed, resume it.
  Future<void> restore() async {
    final snapshot = ref.read(activeTripStoreProvider).read();
    if (snapshot == null) return;
    await _bridge.start();
    state = TripState(trip: snapshot.trip);
  }

  /// Used when the user opens the app from the alarm notification.
  void markRinging() {
    if (state.active) state = state.copyWith(ringing: true);
  }

  void snooze() {
    _bridge.send('snooze');
    state = state.copyWith(ringing: false);
  }

  /// "Dismiss" on the alarm screen: the trip is finished and saved to the history.
  Future<void> dismiss() => _end('dismiss', TripStatus.completed);

  /// "Cancel Trip".
  Future<void> cancel() => _end('stop', TripStatus.cancelled);

  Future<void> cancelIfActive() async {
    if (state.active) await cancel();
  }

  Future<void> _end(String command, TripStatus status) async {
    final trip = state.trip;
    final running = await _bridge.isRunning();
    if (running) {
      _bridge.send(command);
    } else if (trip != null) {
      // The service is gone (killed by the system): save the history ourselves.
      await ref.read(tripRepositoryProvider).save(trip.finish(status));
    }
    await ref.read(activeTripStoreProvider).clear();
    state = const TripState();
  }
}

final tripControllerProvider = NotifierProvider<TripController, TripState>(
  TripController.new,
);

// ---------------------------------------------------------------------------
// Sound preview (the round teal play button)
// ---------------------------------------------------------------------------

class PreviewController extends Notifier<bool> {
  final AlarmPlayer _player = AlarmPlayer();
  bool _disposed = false;

  @override
  bool build() {
    ref.onDispose(() {
      _disposed = true;
      _player.stop();
    });
    return false;
  }

  /// Plays the chosen sound for 5 seconds, or stops it if it is already playing.
  Future<void> toggle(AppSettings settings) async {
    if (state) {
      await _player.stop();
      state = false;
      return;
    }
    state = true;
    await _player.start(mode: settings.soundMode, path: settings.soundPath, vibrate: false);
    await Future<void>.delayed(const Duration(seconds: 5));
    if (_disposed || !state) return;
    await _player.stop();
    state = false;
  }
}

final previewProvider = NotifierProvider<PreviewController, bool>(PreviewController.new);

// ---------------------------------------------------------------------------
// Set in main(): true when the app was opened from the alarm notification
// ---------------------------------------------------------------------------

class LaunchFlagController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final launchedFromAlarmProvider = NotifierProvider<LaunchFlagController, bool>(
  LaunchFlagController.new,
);
