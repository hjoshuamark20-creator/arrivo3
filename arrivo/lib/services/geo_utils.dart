import 'dart:math' as math;

import '../models/app_settings.dart';

/// Great-circle distance between two coordinates, in meters (haversine formula).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(a)));
}

/// "800 m", "1.2 km", "164 ft" or "0.5 mi" depending on the unit setting.
String formatDistance(double meters, DistanceUnit units) {
  if (units == DistanceUnit.km) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  final miles = meters / 1609.344;
  if (miles < 0.1) return '${(meters * 3.28084).round()} ft';
  return '${miles.toStringAsFixed(1)} mi';
}

/// Rough time to arrival from the current speed. Null when barely moving.
Duration? estimateEta(double distanceMeters, double speedMetersPerSecond) {
  if (speedMetersPerSecond < 1.0) return null;
  return Duration(seconds: (distanceMeters / speedMetersPerSecond).round());
}

/// Map zoom level that fits [meters] across about [pixels] screen pixels.
double zoomForSpan(double meters, double latitude, {double pixels = 220}) {
  final metersPerPixel = math.max(meters, 1) / pixels;
  final zoom = math.log(156543.03392 * math.cos(latitude * math.pi / 180) / metersPerPixel) / math.ln2;
  return zoom.clamp(3.0, 18.0).toDouble();
}
