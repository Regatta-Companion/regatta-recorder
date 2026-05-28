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
  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);
    final recorder = ref.watch(recorderProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final display = _formatDisplay(timer);

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
        child: Column(
          children: [
            const SizedBox(height: 16),
            _TimerDisplay(display: display, timer: timer),
            const SizedBox(height: 8),
            _TimerLabel(timer: timer),
            const SizedBox(height: 24),
            _TimerControls(timer: timer),
            const SizedBox(height: 32),
            _RecorderSection(recorder: recorder),
            const Spacer(),
            _StatusBar(
                recorder: recorder,
                settings: settingsAsync.valueOrNull),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDisplay(tm.TimerState timer) {
    final notifier = ref.read(timerProvider.notifier);
    return timer.isCountingDown
        ? notifier.format(timer.remaining)
        : notifier.format(timer.raceElapsed);
  }
}

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
      child: Text(label,
          style: const TextStyle(color: AppColors.teal, fontSize: 13)),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final String display;
  final tm.TimerState timer;
  const _TimerDisplay({required this.display, required this.timer});

  @override
  Widget build(BuildContext context) {
    final color = timer.isCountingDown
        ? (timer.remaining.inSeconds <= 10 && timer.isRunning
            ? AppColors.red
            : AppColors.white)
        : AppColors.teal;

    final prefix = timer.isCountingDown ? '-' : '';

    return Text(
      '$prefix$display',
      style:
          Theme.of(context).textTheme.displayLarge?.copyWith(color: color),
    );
  }
}

class _TimerLabel extends StatelessWidget {
  final tm.TimerState timer;
  const _TimerLabel({required this.timer});

  @override
  Widget build(BuildContext context) {
    String label;
    if (timer.status == tm.TimerStatus.idle) {
      label = timer.hasCountdown ? 'Klaar voor start' : 'Timer uit';
    } else if (timer.status == tm.TimerStatus.paused) {
      label = 'Gepauzeerd';
    } else if (timer.isCountingDown) {
      label = 'Aftellen...';
    } else {
      label = 'Racen! 🏁';
    }
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _TimerControls extends ConsumerWidget {
  final tm.TimerState timer;
  const _TimerControls({required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timerProvider.notifier);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timer.status == tm.TimerStatus.idle) ...[
          _PresetButton(
            label: "5'",
            active: settings?.timerPreset == TimerPreset.min5,
            onTap: () {
              notifier.setToPreset(TimerPreset.min5);
              ref
                  .read(settingsProvider.notifier)
                  .setTimerPreset(TimerPreset.min5);
            },
          ),
          const SizedBox(width: 8),
          _PresetButton(
            label: "10'",
            active: settings?.timerPreset == TimerPreset.min10,
            onTap: () {
              notifier.setToPreset(TimerPreset.min10);
              ref
                  .read(settingsProvider.notifier)
                  .setTimerPreset(TimerPreset.min10);
            },
          ),
          const SizedBox(width: 8),
          _PresetButton(
            label: "15'",
            active: settings?.timerPreset == TimerPreset.min15,
            onTap: () {
              notifier.setToPreset(TimerPreset.min15);
              ref
                  .read(settingsProvider.notifier)
                  .setTimerPreset(TimerPreset.min15);
            },
          ),
          const SizedBox(width: 16),
        ],
        if (timer.status != tm.TimerStatus.running)
          ElevatedButton.icon(
            onPressed: () => notifier.start(),
            icon: const Icon(Icons.play_arrow),
            label: Text(
                timer.status == tm.TimerStatus.paused ? 'Hervat' : 'Start'),
          )
        else
          ElevatedButton.icon(
            onPressed: () => notifier.stop(),
            icon: const Icon(Icons.pause),
            label: const Text('Pauze'),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
          ),
        const SizedBox(width: 12),
        IconButton.outlined(
          onPressed: () => notifier.reset(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset',
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PresetButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.teal.withValues(alpha: 0.2)
              : AppColors.navyLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.teal : AppColors.greyDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.teal : AppColors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _RecorderSection extends ConsumerWidget {
  final RecorderState recorder;
  const _RecorderSection({required this.recorder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recorderProvider.notifier);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  recorder.status == RecorderStatus.recording
                      ? Icons.fiber_manual_record
                      : Icons.gps_fixed,
                  color: recorder.status == RecorderStatus.recording
                      ? AppColors.red
                      : AppColors.teal,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  recorder.status == RecorderStatus.recording
                      ? 'Opnemen...'
                      : recorder.status == RecorderStatus.uploading
                          ? 'Uploaden...'
                          : recorder.status == RecorderStatus.done
                              ? 'Opname voltooid ✓'
                              : 'GPS Recorder',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20),
                ),
              ],
            ),
            if (recorder.status == RecorderStatus.recording) ...[
              const SizedBox(height: 12),
              Text(
                _formatElapsed(recorder.elapsed),
                style: const TextStyle(
                    fontSize: 32,
                    fontFamily: 'monospace',
                    color: AppColors.teal),
              ),
              const SizedBox(height: 4),
              Text(
                '${recorder.pointCount} punten',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            if (recorder.status == RecorderStatus.uploading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.teal),
            ],
            if (recorder.error != null) ...[
              const SizedBox(height: 8),
              Text(
                recorder.error!,
                style: const TextStyle(color: AppColors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            if (recorder.canStart)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => notifier.startRecording(),
                  icon: const Icon(Icons.fiber_manual_record),
                  label: Text(
                    settings?.authToken != null
                        ? 'Start opname'
                        : 'Start opname (niet ingelogd)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                  ),
                ),
              )
            else if (recorder.canStop)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => notifier.stopRecording(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop opname'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber),
                ),
              )
            else if (recorder.status == RecorderStatus.done)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => notifier.reset(),
                  icon: const Icon(Icons.check),
                  label: const Text('Nieuwe opname'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

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
          const SizedBox(width: 16),
          _StatusDot(
            active: hasCode,
            label: hasCode ? 'Code: ${settings!.raceCode}' : 'Geen code',
          ),
          const SizedBox(width: 16),
          _StatusDot(
            active: recorder.pointCount > 0,
            label: '${recorder.pointCount} pts',
          ),
        ],
      ),
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
            style: const TextStyle(fontSize: 12, color: AppColors.grey)),
      ],
    );
  }
}
