// lib/services/background_service.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Background service that keeps the app alive during screen-off recording.
///
/// Android kills apps in the background unless they run a foreground service
/// with a visible notification. This service does exactly that — it doesn't
/// move GPS/timer logic here (that stays in the main isolate), it just tells
/// Android "this process is doing important work, don't kill me."
class BackgroundServiceManager {
  static const String _channel = 'regatta_recorder_bg';

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: null,
        onBackground: null,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        autoStartOnBoot: false,
        notificationChannelId: 'regatta_recorder_channel',
        initialNotificationTitle: 'Regatta Recorder',
        initialNotificationContent: 'Klaar om op te nemen',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> _onStart(ServiceInstance service) async {
    // This runs when the service starts. We don't do GPS/timer here —
    // those run in the main isolate which stays alive because of this
    // foreground service. We just need the service to exist.
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    return true;
  }

  static Future<void> startRecording() async {
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
    }
    service.invoke('setAsForeground', {
      'notificationTitle': 'Regatta Recorder',
      'notificationContent': 'GPS en timer actief — opname loopt',
    });
  }

  static Future<void> stopRecording() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
