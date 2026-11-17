import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/trip.dart';
import '../models/tracking_update.dart';
import 'alarm_player.dart';
import 'geo_utils.dart';
import 'geofence_engine.dart';
import 'notification_service.dart';
import 'storage_services.dart';

const _foregroundNotificationId = 4101;

/// UI side of the background service: starts it, sends commands, receives events.
///
/// Commands sent to the service: 'dismiss', 'snooze', 'stop' (cancel trip).
/// Events received: update, ring, snoozed, ended, error.
class TrackingBridge {
  TrackingBridge([FlutterBackgroundService? service])
      : _service = service ?? FlutterBackgroundService();

  final FlutterBackgroundService _service;
  final StreamController<TrackingEvent> _controller = StreamController.broadcast();
  bool _wired = false;

  /// Call once in main() before runApp (after the notification channels exist).
  Future<void> configure() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onTrackingStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NotificationService.trackingChannelId,
        initialNotificationTitle: 'Arrivo',
        initialNotificationContent: 'Starting your trip...',
        foregroundServiceNotificationId: _foregroundNotificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onTrackingStart,
        onBackground: onTrackingIosBackground,
      ),
    );
  }

  Stream<TrackingEvent> get events {
    _wire();
    return _controller.stream;
  }

  void _wire() {
    if (_wired) return;
    _wired = true;
    _service.on('update').listen((data) {
      if (data == null) return;
      _controller.add(TrackingEvent(
        TrackingEventType.update,
        update: TrackingUpdate.fromMap(Map<String, dynamic>.from(data)),
      ));
    });
    _service.on('ring').listen((data) {
      _controller.add(TrackingEvent(
        TrackingEventType.ring,
        distanceMeters: (data?['distance'] as num?)?.toDouble(),
      ));
    });
    _service.on('snoozed').listen((_) {
      _controller.add(const TrackingEvent(TrackingEventType.snoozed));
    });
    _service.on('ended').listen((_) {
      _controller.add(const TrackingEvent(TrackingEventType.ended));
    });
    _service.on('error').listen((data) {
      _controller.add(TrackingEvent(
        TrackingEventType.error,
        message: data?['message'] as String?,
      ));
    });
  }

  Future<bool> isRunning() => _service.isRunning();

  /// The trip must already be saved in [ActiveTripStore]; the service reads it from there.
  Future<void> start() async {
    _wire();
    if (!await _service.isRunning()) {
      await _service.startService();
    }
  }

  void send(String command) => _service.invoke(command);
}

@pragma('vm:entry-point')
Future<bool> onTrackingIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Entry point of the background isolate. It keeps running with the screen off.
@pragma('vm:entry-point')
Future<void> onTrackingStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final store = ActiveTripStore(prefs);
  final snapshot = store.read();
  if (snapshot == null) {
    await service.stopSelf();
    return;
  }
  final s = service;
  if (s is AndroidServiceInstance) {
    await s.setAsForegroundService();
  }
  final runner = _TripRunner(
    service: service,
    trip: snapshot.trip,
    settings: snapshot.settings,
    history: TripRepository(AppDatabase.instance),
    store: store,
  );
  await runner.start();
}

class _TripRunner {
  _TripRunner({
    required this.service,
    required this.trip,
    required this.settings,
    required this.history,
    required this.store,
  }) : _engine = GeofenceEngine(
          destinationLatitude: trip.latitude,
          destinationLongitude: trip.longitude,
          radiusMeters: trip.radiusMeters,
        );

  final ServiceInstance service;
  final Trip trip;
  final AppSettings settings;
  final TripRepository history;
  final ActiveTripStore store;

  final GeofenceEngine _engine;
  final AlarmPlayer _alarm = AlarmPlayer();
  final NotificationService _notifications = NotificationService();
  StreamSubscription<Position>? _positionSub;
  TrackingBand _band = TrackingBand.far;
  bool _finished = false;

  Future<void> start() async {
    await _notifications.init();
    service.on('dismiss').listen((_) => _finish(TripStatus.completed));
    service.on('snooze').listen((_) => _snooze());
    service.on('stop').listen((_) => _finish(TripStatus.cancelled));
    _listen(_band);
  }

  void _listen(TrackingBand band) {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: band.distanceFilterMeters,
      ),
    ).listen(_onPosition, onError: _onError);
  }

  void _onError(Object error) {
    service.invoke('error', {
      'message': error is LocationServiceDisabledException
          ? 'GPS is off. Turn on location to keep tracking.'
          : 'Lost the GPS signal. Trying again...',
    });
  }

  void _onPosition(Position p) {
    if (_finished) return;
    final result = _engine.update(GeoSample(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      timestamp: DateTime.now(),
      speed: p.speed,
    ));
    service.invoke(
      'update',
      TrackingUpdate(
        distanceMeters: result.distanceMeters ?? -1,
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        speed: p.speed,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        ignored: result.ignored,
      ).toMap(),
    );

    final distance = result.distanceMeters;
    if (result.ignored || distance == null) return;

    _updateForegroundNotification(distance);

    // Ask for GPS more often as the user gets closer (saves battery when far).
    final newBand = bandFor(distance, trip.radiusMeters);
    if (newBand != _band) {
      _band = newBand;
      _listen(newBand);
    }

    if (result.shouldRing) {
      unawaited(_ring(distance));
    }
  }

  void _updateForegroundNotification(double distance) {
    final s = service;
    if (s is AndroidServiceInstance) {
      s.setForegroundNotificationInfo(
        title: 'Arrivo: trip in progress',
        content: '${formatDistance(distance, settings.units)} to ${trip.destinationName}',
      );
    }
  }

  Future<void> _ring(double distance) async {
    await _alarm.start(mode: settings.soundMode, path: settings.soundPath, vibrate: settings.vibration);
    await _notifications.showAlarm(
      destination: trip.destinationName,
      distanceText: formatDistance(distance, settings.units),
    );
    service.invoke('ring', {'distance': distance});
  }

  Future<void> _snooze() async {
    await _alarm.stop();
    await _notifications.cancelAlarm();
    _engine.snooze(DateTime.now(), AppConstants.snoozeDuration);
    service.invoke('snoozed');
  }

  Future<void> _finish(TripStatus status) async {
    if (_finished) return;
    _finished = true;
    _engine.dismiss();
    await _positionSub?.cancel();
    await _alarm.stop();
    await _notifications.cancelAlarm();
    try {
      await history.save(trip.finish(status));
    } catch (_) {}
    await store.clear();
    service.invoke('ended', {'status': status.name});
    await service.stopSelf();
  }
}
