// lib/services/gps_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsPoint {
  final double latitude;
  final double longitude;
  final double speedMs;
  final double headingDeg;
  final DateTime timestamp;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.speedMs,
    required this.headingDeg,
    required this.timestamp,
  });
}

class GpsService {
  Stream<GpsPoint>? _stream;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Try to get a single position to verify GPS is working.
  /// Returns true if GPS is available, false otherwise.
  Future<bool> checkGpsAvailable() async {
    try {
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<GpsPoint> get positionStream {
    if (_stream != null) return _stream!;

    try {
      _stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).map((p) => GpsPoint(
            latitude: p.latitude,
            longitude: p.longitude,
            speedMs: p.speed < 0 ? 0 : p.speed,
            headingDeg: p.heading,
            timestamp: p.timestamp,
          )).handleError((error, stackTrace) {
        // GPS not available or permission denied — silently drop errors
      });
    } catch (_) {
      _stream = const Stream.empty();
    }

    return _stream!;
  }
}
