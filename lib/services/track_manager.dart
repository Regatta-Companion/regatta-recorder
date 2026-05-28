// lib/services/track_manager.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Tracks lokaal opgeslagen GPX bestanden en hun status.
class TrackManager {
  Future<List<File>> listLocalTracks() async {
    final dir = await getApplicationSupportDirectory();
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.gpx'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  Future<void> deleteTrack(File file) async {
    if (await file.exists()) await file.delete();
  }

  /// Formatteert een bestandsnaam naar leesbare datum/tijd.
  /// Verwacht formaat: track_2026-05-28T14-30-00.gpx
  String formatTrackName(String filename) {
    final name = filename.replaceFirst('track_', '').replaceFirst('.gpx', '');
    return name.replaceAll('T', ' ').replaceAll('-', ':').substring(0, 19);
  }
}
