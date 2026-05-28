// lib/services/gps_service.dart
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
    if (permission == LocationPermission.denied) return false;
    if (permission == LocationPermission.deniedForever) return false;

    // Request background location — needed for screen-off recording
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Stream<GpsPoint> get positionStream {
    _stream ??= Geolocator.getPositionStream(
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
        ));
    return _stream!;
  }
}
