// lib/models/timer_state.dart
enum TimerStatus { idle, running, paused }

class TimerState {
  final TimerStatus status;
  final Duration duration;   // configured countdown duration (0 = no countdown)
  final Duration remaining;   // remaining countdown
  final int raceElapsedSeconds; // seconds since countdown hit 0

  const TimerState({
    required this.status,
    required this.duration,
    required this.remaining,
    this.raceElapsedSeconds = 0,
  });

  factory TimerState.initial(Duration countdown) => TimerState(
        status: TimerStatus.idle,
        duration: countdown,
        remaining: countdown,
      );

  bool get isRunning => status == TimerStatus.running;
  bool get isCountingDown => remaining > Duration.zero;
  bool get hasCountdown => duration > Duration.zero;

  Duration get raceElapsed => Duration(seconds: raceElapsedSeconds);

  TimerState copyWith({
    TimerStatus? status,
    Duration? duration,
    Duration? remaining,
    int? raceElapsedSeconds,
  }) =>
      TimerState(
        status: status ?? this.status,
        duration: duration ?? this.duration,
        remaining: remaining ?? this.remaining,
        raceElapsedSeconds: raceElapsedSeconds ?? this.raceElapsedSeconds,
      );
}
