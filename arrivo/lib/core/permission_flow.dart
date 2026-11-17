import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/permission_service.dart';
import '../widgets/glass_dialog.dart';

/// Asks for everything a trip needs. Returns true when the trip can start.
Future<bool> ensureTripPermissions(BuildContext context, WidgetRef ref) async {
  final perms = ref.read(permissionServiceProvider);
  final access = await perms.requestLocation();
  if (!context.mounted) return false;

  switch (access) {
    case LocationAccess.serviceOff:
      final open = await showGlassConfirm(
        context,
        title: 'Turn on location',
        message: 'GPS is off. Turn on location so Arrivo can measure your distance to the stop.',
        confirmLabel: 'Open settings',
        cancelLabel: 'Not now',
      );
      if (open) await perms.openLocationSettings();
      return false;
    case LocationAccess.denied:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is needed to start a trip.')),
      );
      return false;
    case LocationAccess.permanentlyDenied:
      final open = await showGlassConfirm(
        context,
        title: 'Location is blocked',
        message: 'Allow location for Arrivo in the app settings to use the alarm.',
        confirmLabel: 'Open app settings',
        cancelLabel: 'Not now',
      );
      if (open) await perms.openAppSettingsPage();
      return false;
    case LocationAccess.foregroundOnly:
      final goOn = await showGlassConfirm(
        context,
        title: 'Allow location “all the time”',
        message: 'Without it, the alarm may not ring when the screen is off. '
            'Open settings to change it, or continue anyway.',
        confirmLabel: 'Continue anyway',
        cancelLabel: 'Open settings',
      );
      if (!goOn) {
        await perms.openAppSettingsPage();
        return false;
      }
    case LocationAccess.granted:
      break;
  }

  await perms.requestNotifications();
  return true;
}
