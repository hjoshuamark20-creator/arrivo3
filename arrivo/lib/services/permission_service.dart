import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationAccess { granted, foregroundOnly, denied, permanentlyDenied, serviceOff }

/// Location, notification and battery permissions.
/// Android 11+ needs the "while in use" permission first, then "all the time".
class PermissionService {
  Future<LocationAccess> checkLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    if (await Permission.locationAlways.status.isGranted) return LocationAccess.granted;
    final whenInUse = await Permission.locationWhenInUse.status;
    if (whenInUse.isGranted) return LocationAccess.foregroundOnly;
    if (whenInUse.isPermanentlyDenied) return LocationAccess.permanentlyDenied;
    return LocationAccess.denied;
  }

  Future<LocationAccess> requestLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    final whenInUse = await Permission.locationWhenInUse.request();
    if (whenInUse.isPermanentlyDenied) return LocationAccess.permanentlyDenied;
    if (!whenInUse.isGranted) return LocationAccess.denied;
    final always = await Permission.locationAlways.request();
    return always.isGranted ? LocationAccess.granted : LocationAccess.foregroundOnly;
  }

  Future<bool> requestNotifications() async =>
      (await Permission.notification.request()).isGranted;

  /// Shows the system dialog that exempts Arrivo from battery optimization.
  Future<void> requestIgnoreBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<bool> openAppSettingsPage() => openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
