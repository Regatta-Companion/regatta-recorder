// lib/providers/timer_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../models/app_settings.dart';
import 'settings_provider.dart';

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final duration = settings?.timerPreset.duration ?? const Duration(minutes: 5);
    return TimerState.initial(duration);
  }

  /// Update countdown duration from settings.
  void _syncDuration() {
    final settings = ref.read(settingsProvider).valueOrNull;
    final d = settings?.timerPreset.duration ?? const Duration(minutes: 5);
    if (state.status == TimerStatus.idle) {
      state = state.copyWith(duration: d, remaining: d);
    }
  }

  void start() {
    if (state.status == TimerStatus.running) return;
    _syncDuration();
    state = state.copyWith(status: TimerStatus.running);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _ticker?.cancel();
    if (state.status == TimerStatus.running) {
      state = state.copyWith(status: TimerStatus.paused);
    }
  }

  void reset() {
    _ticker?.cancel();
    _syncDuration();
    state = TimerState.initial(state.duration);
  }

  void setToPreset(TimerPreset preset) {
    final d = preset.duration;
    _ticker?.cancel();
    state = TimerState.initial(d);
  }

  void _tick() {
    if (state.remaining > Duration.zero) {
      state = state.copyWith(
        remaining: state.remaining - const Duration(seconds: 1),
      );
    } else if (state.isRunning) {
      state = state.copyWith(
        raceElapsedSeconds: state.raceElapsedSeconds + 1,
      );
    }
  }

  String format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
