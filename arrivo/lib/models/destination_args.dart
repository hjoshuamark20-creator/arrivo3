/// What the Set Alarm screen needs to know about the chosen stop.
class DestinationArgs {
  const DestinationArgs({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// Optional: pre-fill the radius (for example from a saved place).
  final double? radiusMeters;
}
