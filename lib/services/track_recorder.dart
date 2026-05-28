// lib/services/track_recorder.dart
import 'dart:async';
import 'dart:io';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import 'gps_service.dart';

class TrackRecorder {
  final List<GpsPoint> _points = [];
  bool _recording = false;
  StreamSubscription<GpsPoint>? _gpsSub;

  bool get isRecording => _recording;
  int get pointCount => _points.length;

  /// Start recording GPS points from [gpsStream].
  void start(Stream<GpsPoint> gpsStream) {
    _points.clear();
    _gpsSub?.cancel();
    _gpsSub = gpsStream.listen((p) {
      if (_recording) _points.add(p);
    });
    _recording = true;
  }

  /// Stop recording. Returns the saved GPX file, or null if no points.
  Future<File?> stop() async {
    _gpsSub?.cancel();
    _gpsSub = null;
    _recording = false;
    if (_points.isEmpty) return null;
    return _writeGpx();
  }

  Future<File> _writeGpx() async {
    final dir = await getApplicationSupportDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final file = File('${dir.path}/track_$ts.gpx');

    final gpx = Gpx()
      ..creator = 'Regatta Recorder'
      ..trks = [
        Trk(
          name: 'Race $ts',
          trksegs: [
            Trkseg(
              trkpts: _points
                  .map((p) => Wpt(
                        lat: p.latitude,
                        lon: p.longitude,
                        time: p.timestamp,
                      ))
                  .toList(),
            )
          ],
        )
      ];

    await file.writeAsString(GpxWriter().asString(gpx, pretty: true));
    return file;
  }
}
