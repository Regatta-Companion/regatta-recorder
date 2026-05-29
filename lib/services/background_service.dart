// lib/services/background_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Foreground service that keeps the app alive during screen-off recording.
///
/// The notification channel is created in MainActivity.kt *before* the service
/// starts, which fixes the "Bad notification for startForeground" crash on
/// Xiaomi/MIUI where the auto-created channel fails.
///
/// Uses dataSync type instead of location to avoid Android 14+ restrictions.
class BackgroundServiceManager {
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
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> _onStart(ServiceInstance service) async {
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
    try {
      final service = FlutterBackgroundService();
      if (!(await service.isRunning())) {
        await service.startService();
      }
      service.invoke('setAsForeground', {
        'notificationTitle': 'Regatta Recorder',
        'notificationContent': 'GPS en timer actief — opname loopt',
      });
    } catch (_) {
      // Silently ignore — recording works without foreground service
    }
  }

  static Future<void> stopRecording() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
    } catch (_) {
      // Silently ignore
    }
  }
}
