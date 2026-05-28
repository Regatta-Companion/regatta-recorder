// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.read(settingsServiceProvider).load();
  }

  Future<void> save(AppSettings s) async {
    await ref.read(settingsServiceProvider).save(s);
    state = AsyncData(s);
  }

  // ── Auth ──
  Future<void> login(String email, String password) async {
    final data =
        await ref.read(apiServiceProvider).login(email, password);
    final token = data['token'] as String;
    final s = (state.valueOrNull ?? AppSettings.defaults())
        .copyWith(authToken: token, authEmail: email);
    await save(s);

    // Sync profile from server (boat info)
    try {
      final profile =
          await ref.read(apiServiceProvider).getProfile(token);
      final updated = (state.valueOrNull ?? s).copyWith(
        boatType: profile['boat_type'] as String?,
        boatName: profile['boat_name'] as String?,
        teamName: profile['team_name'] as String?,
      );
      await save(updated);
    } catch (_) {
      // Profile sync is best-effort
    }
  }

  Future<void> register(String email, String password) async {
    final data =
        await ref.read(apiServiceProvider).register(email, password);
    final token = data['token'] as String;
    final s = (state.valueOrNull ?? AppSettings.defaults())
        .copyWith(authToken: token, authEmail: email);
    await save(s);
  }

  Future<void> logout() async {
    final s = (state.valueOrNull ?? AppSettings.defaults())
        .copyWith(authToken: null, authEmail: null);
    await save(s);
  }

  // ── Race code ──
  Future<void> setRaceCode(String code, String label) async {
    final s = (state.valueOrNull ?? AppSettings.defaults())
        .copyWith(raceCode: code, raceLabel: label);
    await save(s);
  }

  // ── Boat profile ──
  Future<void> updateBoatProfile({
    String? boatType,
    String? boatName,
    String? teamName,
  }) async {
    final s = (state.valueOrNull ?? AppSettings.defaults()).copyWith(
      boatType: boatType,
      boatName: boatName,
      teamName: teamName,
    );
    await save(s);

    // Also push to server if logged in
    final token = s.authToken;
    if (token != null && token.isNotEmpty) {
      try {
        await ref.read(apiServiceProvider).updateProfile(token, {
          if (boatType != null) 'boat_type': boatType,
          if (boatName != null) 'boat_name': boatName,
          if (teamName != null) 'team_name': teamName,
        });
      } catch (_) {
        // Best-effort server sync
      }
    }
  }

  // ── Timer preset ──
  Future<void> setTimerPreset(TimerPreset preset) async {
    final s = (state.valueOrNull ?? AppSettings.defaults())
        .copyWith(timerPreset: preset);
    await save(s);
  }

  // ── Auth state ──
  bool get isLoggedIn =>
      state.valueOrNull?.authToken?.isNotEmpty == true;
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
