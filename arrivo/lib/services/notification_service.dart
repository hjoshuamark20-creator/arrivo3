import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications. Used in the app and in the background service isolate.
class NotificationService {
  static const trackingChannelId = 'arrivo_tracking';
  static const alarmChannelId = 'arrivo_alarm';
  static const alarmNotificationId = 4102;
  static const alarmPayload = 'alarm';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// [onTap] is called when the user taps a notification (route to the alarm screen).
  Future<void> init({void Function(NotificationResponse response)? onTap}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings, onDidReceiveNotificationResponse: onTap);

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // The foreground-service channel must exist before the service starts.
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      trackingChannelId,
      'Trip tracking',
      description: 'Shown while Arrivo watches your trip.',
      importance: Importance.low,
    ));
    // The alarm sound and vibration come from AlarmPlayer, not from the channel.
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      alarmChannelId,
      'Arrival alarm',
      description: 'Rings when you are close to your stop.',
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
    ));
  }

  /// Full-screen notification so the alarm appears over the lock screen.
  Future<void> showAlarm({required String destination, required String distanceText}) {
    return _plugin.show(
      alarmNotificationId,
      'You’re almost there!',
      '$destination is $distanceText away',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          alarmChannelId,
          'Arrival alarm',
          channelDescription: 'Rings when you are close to your stop.',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: alarmPayload,
    );
  }

  Future<void> cancelAlarm() => _plugin.cancel(alarmNotificationId);

  /// True when the app was opened by tapping (or by the full-screen intent of) the alarm.
  Future<bool> launchedFromAlarm() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false) &&
        details?.notificationResponse?.payload == alarmPayload;
  }

  /// Android 13+ notification permission prompt.
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return (await android?.requestNotificationsPermission()) ?? true;
  }
}
