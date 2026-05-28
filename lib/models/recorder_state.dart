// lib/models/recorder_state.dart
import 'dart:io';

enum RecorderStatus { idle, recording, uploading, done }

class RecorderState {
  final RecorderStatus status;
  final int pointCount;
  final DateTime? startTime;
  final Duration elapsed;
  final String? error;
  final File? lastGpxFile;

  const RecorderState({
    this.status = RecorderStatus.idle,
    this.pointCount = 0,
    this.startTime,
    this.elapsed = Duration.zero,
    this.error,
    this.lastGpxFile,
  });

  bool get canStart => status == RecorderStatus.idle;
  bool get canStop => status == RecorderStatus.recording;

  RecorderState copyWith({
    RecorderStatus? status,
    int? pointCount,
    DateTime? startTime,
    Duration? elapsed,
    String? error,
    Object? lastGpxFile,
  }) =>
      RecorderState(
        status: status ?? this.status,
        pointCount: pointCount ?? this.pointCount,
        startTime: startTime ?? this.startTime,
        elapsed: elapsed ?? this.elapsed,
        error: error,
        lastGpxFile:
            lastGpxFile == _sentinel ? null : (lastGpxFile as File?) ?? this.lastGpxFile,
      );

  static const _sentinel = Object();
}
