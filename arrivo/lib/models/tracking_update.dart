/// One position report sent from the background service to the UI.
class TrackingUpdate {
  const TrackingUpdate({
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.timestampMs,
    this.ignored = false,
  });

  /// Smoothed distance to the stop in meters, or -1 if no usable fix yet.
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final int timestampMs;

  /// True when the reading was too inaccurate to use.
  final bool ignored;

  bool get hasDistance => distanceMeters >= 0;

  Map<String, dynamic> toMap() => {
        'distance': distanceMeters,
        'lat': latitude,
        'lng': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'ts': timestampMs,
        'ignored': ignored,
      };

  factory TrackingUpdate.fromMap(Map<String, dynamic> map) => TrackingUpdate(
        distanceMeters: (map['distance'] as num?)?.toDouble() ?? -1,
        latitude: (map['lat'] as num?)?.toDouble() ?? 0,
        longitude: (map['lng'] as num?)?.toDouble() ?? 0,
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
        speed: (map['speed'] as num?)?.toDouble() ?? 0,
        timestampMs: (map['ts'] as num?)?.toInt() ?? 0,
        ignored: (map['ignored'] as bool?) ?? false,
      );
}

enum TrackingEventType { update, ring, snoozed, ended, error }

/// Event coming from the background service.
class TrackingEvent {
  const TrackingEvent(this.type, {this.update, this.distanceMeters, this.message});

  final TrackingEventType type;
  final TrackingUpdate? update;
  final double? distanceMeters;
  final String? message;
}
