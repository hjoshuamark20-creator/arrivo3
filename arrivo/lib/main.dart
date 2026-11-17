import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Notification channels must exist before the background service is configured.
  final notifications = container.read(notificationServiceProvider);
  await notifications.init(
    onTap: (response) {
      if (response.payload == NotificationService.alarmPayload) {
        container.read(tripControllerProvider.notifier).markRinging();
      }
    },
  );
  container
      .read(launchedFromAlarmProvider.notifier)
      .set(await notifications.launchedFromAlarm());

  await container.read(trackingBridgeProvider).configure();

  runApp(UncontrolledProviderScope(container: container, child: const ArrivoApp()));
}

class ArrivoApp extends ConsumerWidget {
  const ArrivoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final darkMode = ref.watch(settingsProvider.select((s) => s.darkMode));
    return MaterialApp.router(
      title: 'Arrivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
