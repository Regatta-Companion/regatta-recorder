// lib/services/background_service.dart
//
// DISABLED — foreground service causes native-level crashes on Xiaomi/MIUI
// (CannotPostForegroundServiceNotificationException on startForeground).
// GPS recording still works; Android may kill the app with screen off.
//
// To re-enable: restore the flutter_background_service setup below.

class BackgroundServiceManager {
  static Future<void> initialize() async {
    // Disabled — see comment above.
  }

  static Future<void> startRecording() async {
    // Disabled — see comment above.
  }

  static Future<void> stopRecording() async {
    // Disabled — see comment above.
  }
}
