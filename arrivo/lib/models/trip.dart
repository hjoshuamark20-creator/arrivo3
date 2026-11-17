enum TripStatus { active, completed, cancelled }

/// One trip, saved to the trip history when it ends.
class Trip {
  const Trip({
    required this.id,
    required this.destinationName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.startedAt,
    this.endedAt,
    this.status = TripStatus.active,
  });

  final String id;
  final String destinationName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime startedAt;
  final DateTime? endedAt;
  final TripStatus status;

  Trip finish(TripStatus newStatus) => Trip(
        id: id,
        destinationName: destinationName,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        status: newStatus,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'destination_name': destinationName,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt?.millisecondsSinceEpoch,
        'status': status.name,
      };

  factory Trip.fromMap(Map<String, Object?> map) => Trip(
        id: map['id'] as String,
        destinationName: map['destination_name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        radiusMeters: (map['radius'] as num).toDouble(),
        startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
        endedAt: map['ended_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
        status: TripStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => TripStatus.completed,
        ),
      );
}
