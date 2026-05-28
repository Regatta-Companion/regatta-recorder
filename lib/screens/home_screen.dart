// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart' as tm;
import '../models/app_settings.dart';
import '../models/recorder_state.dart';
import '../providers/timer_provider.dart';
import '../providers/recorder_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _formatDisplay(tm.TimerState timerState) {
    final notifier = ref.read(timerProvider.notifier);
    if (timerState.isCountingDown) {
      return '-${notifier.format(timerState.remaining)}';
    }
    return '+${notifier.format(timerState.raceElapsed)}';
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final recorder = ref.watch(recorderProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final notifier = ref.read(timerProvider.notifier);
    final display = _formatDisplay(timerState);

    // Auto-start recorder when countdown hits 5 minutes remaining
    ref.listen(timerProvider, (prev, next) {
      if (next.isRunning &&
          next.isCountingDown &&
          next.remaining <= const Duration(minutes: 5) &&
          next.remaining > Duration.zero) {
        final rec = ref.read(recorderProvider);
        if (rec.status == RecorderStatus.idle) {
          ref.read(recorderProvider.notifier).startRecording();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regatta Recorder',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (settingsAsync.valueOrNull?.raceCode != null)
            _CodeChip(
                label: settingsAsync.valueOrNull!.raceLabel ??
                    settingsAsync.valueOrNull!.raceCode!),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _LandscapeLayout(
                timerState: timerState,
                recorder: recorder,
                display: display,
                notifier: notifier,
                settings: settingsAsync.valueOrNull,
              );
            }
            return _PortraitLayout(
              timerState: timerState,
              recorder: recorder,
              display: display,
              notifier: notifier,
              settings: settingsAsync.valueOrNull,
            );
          },
        ),
      ),
    );
  }
}

// ─── Portrait Layout ──────────────────────────────────────────────────────────

class _PortraitLayout extends ConsumerWidget {
  final tm.TimerState timerState;
  final RecorderState recorder;
  final String display;
  final dynamic notifier;
  final AppSettings? settings;

  const _PortraitLayout({
    required this.timerState,
    required this.recorder,
    required this.display,
    required this.notifier,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Duration presets (top, compact)
        if (timerState.status == tm.TimerStatus.idle)
          _DurationSelector(
            selected: timerState.duration,
            onSelect: (d) {
              final preset = switch (d.inMinutes) {
                5 => TimerPreset.min5,
                10 => TimerPreset.min10,
                _ => TimerPreset.min15,
              };
              notifier.setToPreset(preset);
              ref.read(settingsProvider.notifier).setTimerPreset(preset);
            },
          ),
        // Timer display (fills screen)
        Expanded(
          flex: 5,
          child: _TimerDisplay(
            display: display,
            timerState: timerState,
          ),
        ),
        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _StartButton(
                  isRunning: timerState.isRunning,
                  onTap:
                      timerState.isRunning ? () => notifier.stop() : () => notifier.start(),
                ),
              ),
              const SizedBox(width: 12),
              _ResetButton(onTap: () => notifier.reset()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Recorder bar
        _RecorderBar(recorder: recorder),
        const SizedBox(height: 4),
        _StatusBar(
            recorder: recorder, settings: settings),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Landscape Layout ─────────────────────────────────────────────────────────

class _LandscapeLayout extends ConsumerWidget {
  final tm.TimerState timerState;
  final RecorderState recorder;
  final String display;
  final dynamic notifier;
  final AppSettings? settings;

  const _LandscapeLayout({
    required this.timerState,
    required this.recorder,
    required this.display,
    required this.notifier,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Left column: presets, controls, recorder
          SizedBox(
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (timerState.status == tm.TimerStatus.idle)
                  _DurationSelector(
                    selected: timerState.duration,
                    onSelect: (d) {
                      final preset = switch (d.inMinutes) {
                        5 => TimerPreset.min5,
                        10 => TimerPreset.min10,
                        _ => TimerPreset.min15,
                      };
                      notifier.setToPreset(preset);
                      ref.read(settingsProvider.notifier).setTimerPreset(preset);
                    },
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StartButton(
                        isRunning: timerState.isRunning,
                        onTap: timerState.isRunning
                            ? () => notifier.stop()
                            : () => notifier.start(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ResetButton(onTap: () => notifier.reset()),
                  ],
                ),
                const SizedBox(height: 8),
                _RecorderBarLandscape(recorder: recorder),
                const SizedBox(height: 4),
                _StatusBarLandscape(
                    recorder: recorder, settings: settings),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: big timer display
          Expanded(
            child: _TimerDisplay(
              display: display,
              timerState: timerState,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Duration selector ────────────────────────────────────────────────────────

class _DurationSelector extends StatelessWidget {
  final Duration selected;
  final void Function(Duration) onSelect;

  const _DurationSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: options
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _DurationChip(
                    label: '${d.inMinutes}m',
                    selected: selected == d,
                    onTap: () => onSelect(d),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.navyLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.navy : AppColors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Timer display (full-screen via FittedBox) ────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  final String display;
  final tm.TimerState timerState;

  const _TimerDisplay({required this.display, required this.timerState});

  @override
  Widget build(BuildContext context) {
    final color = timerState.isCountingDown
        ? (timerState.remaining.inSeconds <= 10 && timerState.isRunning
            ? AppColors.red
            : AppColors.white)
        : AppColors.teal;

    final label = timerState.isCountingDown ? 'AFTELLEN' : 'RACE';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                display,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: color,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Start/Stop button ────────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const _StartButton({required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF166534),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            isRunning ? 'STOP' : 'START',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4ADE80),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reset button ─────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.navyLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'RESET',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ─── Recorder bar (portrait) ──────────────────────────────────────────────────

class _RecorderBar extends ConsumerWidget {
  final RecorderState recorder;
  const _RecorderBar({required this.recorder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recorderProvider.notifier);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                recorder.status == RecorderStatus.recording
                    ? Icons.fiber_manual_record
                    : recorder.status == RecorderStatus.done
                        ? Icons.check_circle
                        : Icons.gps_fixed,
                color: recorder.status == RecorderStatus.recording
                    ? AppColors.red
                    : recorder.status == RecorderStatus.done
                        ? AppColors.green
                        : AppColors.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recorder.status == RecorderStatus.recording
                      ? 'Opnemen — ${recorder.pointCount} pts'
                      : recorder.status == RecorderStatus.uploading
                          ? 'Uploaden...'
                          : recorder.status == RecorderStatus.done
                              ? 'Opname voltooid'
                              : 'GPS Recorder',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (recorder.canStart)
                TextButton.icon(
                  onPressed: () => notifier.startRecording(),
                  icon: const Icon(Icons.fiber_manual_record, size: 18),
                  label: Text(
                    settings?.authToken != null ? 'Start' : 'Start*',
                    style: const TextStyle(color: AppColors.red),
                  ),
                )
              else if (recorder.canStop)
                TextButton.icon(
                  onPressed: () => notifier.stopRecording(),
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                )
              else if (recorder.status == RecorderStatus.done)
                TextButton.icon(
                  onPressed: () => notifier.reset(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Nieuw'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recorder bar (landscape, compact) ────────────────────────────────────────

class _RecorderBarLandscape extends ConsumerWidget {
  final RecorderState recorder;
  const _RecorderBarLandscape({required this.recorder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recorderProvider.notifier);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  recorder.status == RecorderStatus.recording
                      ? Icons.fiber_manual_record
                      : recorder.status == RecorderStatus.done
                          ? Icons.check_circle
                          : Icons.gps_fixed,
                  size: 16,
                  color: recorder.status == RecorderStatus.recording
                      ? AppColors.red
                      : recorder.status == RecorderStatus.done
                          ? AppColors.green
                          : AppColors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  recorder.status == RecorderStatus.recording
                      ? '${recorder.pointCount} pts'
                      : recorder.status == RecorderStatus.done
                          ? 'Klaar'
                          : 'GPS',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            if (recorder.canStart)
              TextButton.icon(
                onPressed: () => notifier.startRecording(),
                icon: const Icon(Icons.fiber_manual_record, size: 14),
                label: Text(
                  settings?.authToken != null ? 'Start' : 'Start*',
                  style: const TextStyle(color: AppColors.red, fontSize: 11),
                ),
              )
            else if (recorder.canStop)
              TextButton.icon(
                onPressed: () => notifier.stopRecording(),
                icon: const Icon(Icons.stop, size: 14),
                label: const Text('Stop',
                    style: TextStyle(fontSize: 11)),
              )
            else if (recorder.status == RecorderStatus.done)
              TextButton.icon(
                onPressed: () => notifier.reset(),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Nieuw',
                    style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Code chip ────────────────────────────────────────────────────────────────

class _CodeChip extends StatelessWidget {
  final String label;
  const _CodeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child:
          Text(label, style: const TextStyle(color: AppColors.teal, fontSize: 13)),
    );
  }
}

// ─── Status bar (portrait) ────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final RecorderState recorder;
  final AppSettings? settings;
  const _StatusBar({required this.recorder, required this.settings});

  @override
  Widget build(BuildContext context) {
    final loggedIn = settings?.authToken?.isNotEmpty == true;
    final hasCode = settings?.raceCode?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatusDot(
            active: loggedIn,
            label: loggedIn ? 'Ingelogd' : 'Niet ingelogd',
          ),
          const SizedBox(width: 12),
          _StatusDot(
            active: hasCode,
            label:
                hasCode ? 'Code: ${settings!.raceCode}' : 'Geen code',
          ),
          const SizedBox(width: 12),
          _StatusDot(
            active: recorder.pointCount > 0,
            label: '${recorder.pointCount} pts',
          ),
        ],
      ),
    );
  }
}

// ─── Status bar (landscape, compact) ──────────────────────────────────────────

class _StatusBarLandscape extends StatelessWidget {
  final RecorderState recorder;
  final AppSettings? settings;
  const _StatusBarLandscape({required this.recorder, required this.settings});

  @override
  Widget build(BuildContext context) {
    final loggedIn = settings?.authToken?.isNotEmpty == true;
    final hasCode = settings?.raceCode?.isNotEmpty == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatusDot(
          active: loggedIn,
          label: loggedIn ? 'Login' : '❌',
        ),
        const SizedBox(width: 8),
        _StatusDot(
          active: hasCode,
          label: hasCode ? settings!.raceCode! : '—',
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StatusDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.teal : AppColors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey)),
      ],
    );
  }
}
