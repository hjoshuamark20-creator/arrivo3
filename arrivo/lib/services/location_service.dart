import 'package:geolocator/geolocator.dart';

/// Location access for the app screens (the background service has its own stream).
class LocationService {
  /// One accurate fix, or null if location is off, denied, or took too long.
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }

  Stream<Position> watch({int distanceFilter = 10}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        ),
      );
}
