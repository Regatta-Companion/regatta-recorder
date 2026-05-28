// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service (foreground notification keeps app alive)
  await BackgroundServiceManager.initialize();

  // Allow portrait and landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Donker overlay stijl voor statusbar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: RegattaRecorderApp()));
}

class RegattaRecorderApp extends ConsumerStatefulWidget {
  const RegattaRecorderApp({super.key});

  @override
  ConsumerState<RegattaRecorderApp> createState() => _RegattaRecorderAppState();
}

class _RegattaRecorderAppState extends ConsumerState<RegattaRecorderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Herstel wakelock als keepScreenOn aanstaat
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings?.keepScreenOn == true) {
        WakelockPlus.enable();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Zet wakelock aan/uit op basis van instellingen
    ref.listen(settingsProvider, (_, next) {
      next.whenData((s) {
        if (s.keepScreenOn) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      });
    });

    return MaterialApp(
      title: 'Regatta Recorder',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
