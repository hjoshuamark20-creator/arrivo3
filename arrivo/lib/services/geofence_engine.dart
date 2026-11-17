import '../core/constants.dart';
import 'geo_utils.dart';

/// A raw GPS reading, decoupled from the geolocator plugin so it is easy to test.
class GeoSample {
  const GeoSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed = 0,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double speed;
}

class GeofenceUpdate {
  const GeofenceUpdate({
    required this.distanceMeters,
    required this.inside,
    required this.shouldRing,
    this.ignored = false,
  });

  /// Smoothed distance in meters. Null until the first usable reading.
  final double? distanceMeters;
  final bool inside;
  final bool shouldRing;

  /// True when the reading was dropped for poor accuracy.
  final bool ignored;
}

/// How often to ask for GPS updates. Far away = rarely, close = often (saves battery).
enum TrackingBand {
  far(100),
  mid(50),
  near(10);

  const TrackingBand(this.distanceFilterMeters);
  final int distanceFilterMeters;
}

TrackingBand bandFor(double distanceMeters, double radiusMeters) {
  final farLimit = radiusMeters * 8 > 5000 ? radiusMeters * 8 : 5000.0;
  final midLimit = radiusMeters * 3 > 1500 ? radiusMeters * 3 : 1500.0;
  if (distanceMeters > farLimit) return TrackingBand.far;
  if (distanceMeters > midLimit) return TrackingBand.mid;
  return TrackingBand.near;
}

/// Pure geofence logic: filters bad readings, smooths the distance, and decides
/// when the alarm should ring. The alarm rings once per approach. After a snooze it
/// can ring again once the snooze time has passed and the user is still inside.
class GeofenceEngine {
  GeofenceEngine({
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.radiusMeters,
    this.maxAccuracyMeters = AppConstants.maxAcceptableAccuracyMeters,
    this.smoothing = 0.6,
  }) : assert(smoothing > 0 && smoothing <= 1, 'smoothing must be in (0, 1]');

  final double destinationLatitude;
  final double destinationLongitude;
  final double radiusMeters;
  final double maxAccuracyMeters;

  /// 1.0 = no smoothing. Lower values follow the previous distance more.
  final double smoothing;

  double? _smoothed;
  DateTime? _snoozeUntil;
  bool _alarmActive = false;
  bool _finished = false;

  bool get alarmActive => _alarmActive;

  GeofenceUpdate update(GeoSample sample) {
    final previous = _smoothed;
    if (sample.accuracy > maxAccuracyMeters) {
      return GeofenceUpdate(
        distanceMeters: previous,
        inside: previous != null && previous <= radiusMeters,
        shouldRing: false,
        ignored: true,
      );
    }

    final raw = distanceMeters(
      sample.latitude,
      sample.longitude,
      destinationLatitude,
      destinationLongitude,
    );
    final smoothed = previous == null ? raw : previous + smoothing * (raw - previous);
    _smoothed = smoothed;

    final inside = smoothed <= radiusMeters;
    final snoozeUntil = _snoozeUntil;
    final snoozeOver = snoozeUntil == null || !sample.timestamp.isBefore(snoozeUntil);
    final ring = inside && !_alarmActive && !_finished && snoozeOver;
    if (ring) {
      _alarmActive = true;
      _snoozeUntil = null;
    }
    return GeofenceUpdate(distanceMeters: smoothed, inside: inside, shouldRing: ring);
  }

  /// Silence the alarm and re-arm it after [duration].
  void snooze(DateTime now, [Duration duration = AppConstants.snoozeDuration]) {
    _alarmActive = false;
    _snoozeUntil = now.add(duration);
  }

  /// The trip is over: never ring again.
  void dismiss() {
    _alarmActive = false;
    _finished = true;
  }
}
