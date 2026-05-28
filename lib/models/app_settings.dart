// lib/models/app_settings.dart

/// Duration presets for the countdown timer.
enum TimerPreset { off, min5, min10, min15 }

extension TimerPresetDuration on TimerPreset {
  Duration get duration => switch (this) {
        TimerPreset.off => Duration.zero,
        TimerPreset.min5 => const Duration(minutes: 5),
        TimerPreset.min10 => const Duration(minutes: 10),
        TimerPreset.min15 => const Duration(minutes: 15),
      };

  String get label => switch (this) {
        TimerPreset.off => 'Uit',
        TimerPreset.min5 => '5 min',
        TimerPreset.min10 => '10 min',
        TimerPreset.min15 => '15 min',
      };
}

class AppSettings {
  // Auth
  final String? authToken;
  final String? authEmail;

  // Race
  final String? raceCode;
  final String? raceLabel;

  // Boat profile
  final String? boatType;
  final String? boatName;
  final String? teamName;

  // Timer
  final TimerPreset timerPreset;

  // Display
  final bool keepScreenOn;

  const AppSettings({
    this.authToken,
    this.authEmail,
    this.raceCode,
    this.raceLabel,
    this.boatType,
    this.boatName,
    this.teamName,
    this.timerPreset = TimerPreset.min5,
    this.keepScreenOn = true,
  });

  factory AppSettings.defaults() => const AppSettings();

  static const _unset = Object();

  AppSettings copyWith({
    Object? authToken = _unset,
    Object? authEmail = _unset,
    Object? raceCode = _unset,
    Object? raceLabel = _unset,
    Object? boatType = _unset,
    Object? boatName = _unset,
    Object? teamName = _unset,
    TimerPreset? timerPreset,
    bool? keepScreenOn,
  }) =>
      AppSettings(
        authToken: authToken == _unset ? this.authToken : authToken as String?,
        authEmail: authEmail == _unset ? this.authEmail : authEmail as String?,
        raceCode: raceCode == _unset ? this.raceCode : raceCode as String?,
        raceLabel: raceLabel == _unset ? this.raceLabel : raceLabel as String?,
        boatType: boatType == _unset ? this.boatType : boatType as String?,
        boatName: boatName == _unset ? this.boatName : boatName as String?,
        teamName: teamName == _unset ? this.teamName : teamName as String?,
        timerPreset: timerPreset ?? this.timerPreset,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      );

  Map<String, dynamic> toJson() => {
        'authToken': authToken,
        'authEmail': authEmail,
        'raceCode': raceCode,
        'raceLabel': raceLabel,
        'boatType': boatType,
        'boatName': boatName,
        'teamName': teamName,
        'timerPreset': timerPreset.name,
        'keepScreenOn': keepScreenOn,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        authToken: j['authToken'] as String?,
        authEmail: j['authEmail'] as String?,
        raceCode: j['raceCode'] as String?,
        raceLabel: j['raceLabel'] as String?,
        boatType: j['boatType'] as String?,
        boatName: j['boatName'] as String?,
        teamName: j['teamName'] as String?,
        timerPreset: TimerPreset.values.byName(
            (j['timerPreset'] as String?) ?? 'min5'),
        keepScreenOn: (j['keepScreenOn'] as bool?) ?? true,
      );
}
