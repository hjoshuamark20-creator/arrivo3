import '../core/constants.dart';

enum SoundMode { phoneDefault, ringtone, file }

enum DistanceUnit { km, mi }

/// User preferences (stored as JSON in SharedPreferences).
class AppSettings {
  const AppSettings({
    this.defaultRadius = AppConstants.defaultRadiusMeters,
    this.soundMode = SoundMode.phoneDefault,
    this.soundPath,
    this.vibration = true,
    this.units = DistanceUnit.km,
    this.darkMode = false,
  });

  final double defaultRadius;
  final SoundMode soundMode;

  /// For [SoundMode.ringtone]: 'alarm', 'ringtone' or 'notification' (the phone's own
  /// tone for that category). For [SoundMode.file]: the stored audio file path.
  final String? soundPath;
  final bool vibration;
  final DistanceUnit units;
  final bool darkMode;

  AppSettings copyWith({
    double? defaultRadius,
    SoundMode? soundMode,
    String? soundPath,
    bool? vibration,
    DistanceUnit? units,
    bool? darkMode,
  }) =>
      AppSettings(
        defaultRadius: defaultRadius ?? this.defaultRadius,
        soundMode: soundMode ?? this.soundMode,
        soundPath: soundPath ?? this.soundPath,
        vibration: vibration ?? this.vibration,
        units: units ?? this.units,
        darkMode: darkMode ?? this.darkMode,
      );

  Map<String, dynamic> toJson() => {
        'defaultRadius': defaultRadius,
        'soundMode': soundMode.name,
        'soundPath': soundPath,
        'vibration': vibration,
        'units': units.name,
        'darkMode': darkMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        defaultRadius: ((json['defaultRadius'] as num?) ?? AppConstants.defaultRadiusMeters)
            .toDouble()
            .clamp(AppConstants.minRadiusMeters, AppConstants.maxRadiusMeters),
        soundMode: SoundMode.values.firstWhere(
          (e) => e.name == json['soundMode'],
          orElse: () => SoundMode.phoneDefault,
        ),
        soundPath: json['soundPath'] as String?,
        vibration: (json['vibration'] as bool?) ?? true,
        units: DistanceUnit.values.firstWhere(
          (e) => e.name == json['units'],
          orElse: () => DistanceUnit.km,
        ),
        darkMode: (json['darkMode'] as bool?) ?? false,
      );
}
