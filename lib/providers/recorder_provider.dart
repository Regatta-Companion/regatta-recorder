// lib/providers/recorder_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recorder_state.dart';
import '../services/background_service.dart';
import '../services/gps_service.dart';
import '../services/track_recorder.dart';
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

  /// Start recording. Keeps screen on + starts foreground service.
  Future<void> startRecording() async {
    try {
      // 1. Permission
      final ok = await requestPermission();
      if (!ok) {
        state = state.copyWith(
          error: 'GPS-toestemming nodig om op te nemen.',
        );
        return;
      }

      // 2. Verify GPS actually works before opening the stream
      final gpsService = ref.read(gpsServiceProvider);
      final gpsReady = await gpsService.checkGpsAvailable();
      if (!gpsReady) {
        state = state.copyWith(
          error: 'GPS nog niet beschikbaar — even wachten.',
        );
        return;
      }

      // 3. Start GPS stream + track recording
      final gpsStream = gpsService.positionStream;
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

      // 4. Start timer
      ref.read(timerProvider.notifier).start();

      // 5. Keep screen on + foreground service for screen-off survival
      WakelockPlus.enable();
      BackgroundServiceManager.startRecording().catchError((_) {});
    } catch (e) {
      state = state.copyWith(
        error: 'Fout bij starten: ${e.toString()}',
      );
    }
  }

  /// Stop recording, save GPX, upload to server, and join race if code set.
  Future<void> stopRecording() async {
    _elapsedTimer?.cancel();

    // Allow screen to sleep + stop foreground service
    WakelockPlus.disable();
    BackgroundServiceManager.stopRecording();

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
    WakelockPlus.disable();
    BackgroundServiceManager.stopRecording();
    state = const RecorderState();
  }
}
