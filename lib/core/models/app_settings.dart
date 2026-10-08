import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_theme.dart';

class AppSettings {
  const AppSettings({
    this.themeVariant = AppThemeVariant.mocha,
    this.followSystemTheme = true,
    this.textScale = 1.0,
    this.soundEnabled = true,
    this.mutedSounds = const <AppSound>{},
    this.hapticsEnabled = true,
    this.reduceMotion = false,
  });

  final AppThemeVariant themeVariant;
  final bool followSystemTheme;
  final double textScale;
  final bool soundEnabled;
  final Set<AppSound> mutedSounds;
  final bool hapticsEnabled;
  final bool reduceMotion;

  AppSettings copyWith({
    AppThemeVariant? themeVariant,
    bool? followSystemTheme,
    double? textScale,
    bool? soundEnabled,
    Set<AppSound>? mutedSounds,
    bool? hapticsEnabled,
    bool? reduceMotion,
  }) {
    return AppSettings(
      themeVariant: themeVariant ?? this.themeVariant,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
      textScale: textScale ?? this.textScale,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      mutedSounds: mutedSounds ?? this.mutedSounds,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeVariant': themeVariant.name,
      'followSystemTheme': followSystemTheme,
      'textScale': textScale,
      'soundEnabled': soundEnabled,
      'mutedSounds': mutedSounds.map((AppSound s) => s.name).toList(),
      'hapticsEnabled': hapticsEnabled,
      'reduceMotion': reduceMotion,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeVariant: AppThemeVariant.values.firstWhere(
        (AppThemeVariant v) => v.name == json['themeVariant'],
        orElse: () => AppThemeVariant.mocha,
      ),
      followSystemTheme: json['followSystemTheme'] as bool? ?? true,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      mutedSounds: (json['mutedSounds'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => AppSound.tryParse(e as String))
          .whereType<AppSound>()
          .toSet(),
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
    );
  }
}
