// lib/providers/recorder_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recorder_state.dart';
import '../models/app_settings.dart';
import '../services/gps_service.dart';
import '../services/track_recorder.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';
import 'timer_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());

final recorderProvider =
    NotifierProvider<RecorderNotifier, RecorderState>(RecorderNotifier.new);

class RecorderNotifier extends Notifier<RecorderState> {
  final TrackRecorder _trackRecorder = TrackRecorder();
  Timer? _elapsedTimer;
  DateTime? _startTime;

  @override
  RecorderState build() => const RecorderState();

  /// Returns true if permission granted and GPS ready.
  Future<bool> requestPermission() async {
    return ref.read(gpsServiceProvider).requestPermission();
  }

  /// Start recording. Automatically starts the timer if not running.
  Future<void> startRecording() async {
    final ok = await requestPermission();
    if (!ok) {
      state = state.copyWith(
        error: 'GPS-toestemming nodig om op te nemen.',
      );
      return;
    }

    final gpsStream = ref.read(gpsServiceProvider).positionStream;
    _trackRecorder.start(gpsStream);
    _startTime = DateTime.now();

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        state = state.copyWith(
          elapsed: DateTime.now().difference(_startTime!),
          pointCount: _trackRecorder.pointCount,
        );
      }
    });

    state = RecorderState(
      status: RecorderStatus.recording,
      startTime: _startTime,
    );

    // Also start the timer
    ref.read(timerProvider.notifier).start();
  }

  /// Stop recording, save GPX, upload to server, and join race if code set.
  Future<void> stopRecording() async {
    _elapsedTimer?.cancel();
    final file = await _trackRecorder.stop();

    state = state.copyWith(
      status: file != null ? RecorderStatus.uploading : RecorderStatus.idle,
      pointCount: _trackRecorder.pointCount,
      error: null,
    );

    if (file == null) {
      state = const RecorderState(); // reset
      return;
    }

    final token = ref.read(settingsProvider).valueOrNull?.authToken;
    if (token == null || token.isEmpty) {
      // Not logged in — just save locally
      state = state.copyWith(
        status: RecorderStatus.done,
        lastGpxFile: file,
      );
      return;
    }

    try {
      // 1. Upload GPX
      await ref.read(apiServiceProvider).uploadTrack(file, token);

      // 2. Join race if code is set
      final code =
          ref.read(settingsProvider).valueOrNull?.raceCode;
      if (code != null && code.isNotEmpty) {
        // Find the uploaded track ID
        final tracks =
            await ref.read(apiServiceProvider).listTracks(token);
        final filename = file.uri.pathSegments.last;
        final match = tracks.cast<Map<String, dynamic>?>().firstWhere(
              (t) => t?['filename'] == filename,
              orElse: () => null,
            );
        if (match != null) {
          final trackId = match['id'] as int;
          await ref
              .read(apiServiceProvider)
              .joinWithCode(token, code, trackId);
        }
      }

      state = state.copyWith(
        status: RecorderStatus.done,
        lastGpxFile: file,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.done,
        error: e.toString(),
        lastGpxFile: file,
      );
    }
  }

  void reset() {
    _elapsedTimer?.cancel();
    _trackRecorder.stop(); // discard
    state = const RecorderState();
  }
}
