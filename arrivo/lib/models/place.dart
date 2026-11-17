/// A saved destination (stored in SQLite).
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Place.fromMap(Map<String, Object?> map) => Place(
        id: map['id'] as String,
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        radiusMeters: (map['radius'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
