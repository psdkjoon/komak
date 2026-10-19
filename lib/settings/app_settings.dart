import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:komak/core/kv_store.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/theme/catppuccin.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs) {
    _importLegacy();
    _themeMode = _byName(
      ThemeMode.values,
      _prefs.getString('themeMode'),
      _themeMode,
    );
    _language = _prefs.getString('language') ?? L10n.system;
    L10n.code = L10n.resolve(_language);
    _checkUpdates = _prefs.getBool('checkUpdates') ?? _checkUpdates;
    final accent = _prefs.getString('accent');
    if (accent != null && CatppuccinPalette.accents.contains(accent)) {
      _accent = accent;
    }
    _appearanceUpdatedAt = _prefs.getInt('accentUpdatedAt') ?? _appearanceUpdatedAt;
    _syncAppearance = _prefs.getBool('syncAccent') ?? _syncAppearance;
    _textScalePercent = _prefs.getInt('textScalePercent') ?? _textScalePercent;
    _soundEnabled = _prefs.getBool('soundEnabled') ?? _soundEnabled;
    _mutedSounds = {
      for (final name in _prefs.getStringList('mutedSounds') ?? <String>[])
        if (AppSound.tryParse(name) case final sound?) sound,
    };
    _hapticsEnabled = _prefs.getBool('hapticsEnabled') ?? _hapticsEnabled;
    _reduceMotion = _prefs.getBool('reduceMotion') ?? _reduceMotion;
  }

  static AppSettings load(KvStore store) => AppSettings._(store);

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static const _legacyKey = 'komak_settings_v1';

  final KvStore _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  String _language = L10n.system;
  bool _checkUpdates = true;
  String _accent = CatppuccinPalette.defaultAccent;
  int _appearanceUpdatedAt = 0;
  bool _syncAppearance = true;
  int _textScalePercent = 100;
  bool _soundEnabled = true;
  Set<AppSound> _mutedSounds = <AppSound>{};
  bool _hapticsEnabled = true;
  bool _reduceMotion = false;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get checkUpdates => _checkUpdates;
  String get accent => _accent;
  int get appearanceUpdatedAt => _appearanceUpdatedAt;
  bool get syncAppearance => _syncAppearance;
  double get textScale => _textScalePercent / 100;
  bool get soundEnabled => _soundEnabled;
  Set<AppSound> get mutedSounds => Set.unmodifiable(_mutedSounds);
  bool get hapticsEnabled => _hapticsEnabled;
  bool get reduceMotion => _reduceMotion;

  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _stamp();
    _set(() => _themeMode = value, 'themeMode', value.name);
  }

  set language(String value) {
    _language = value;
    L10n.code = L10n.resolve(value);
    _prefs.setString('language', value);
    notifyListeners();
  }

  set checkUpdates(bool value) =>
      _set(() => _checkUpdates = value, 'checkUpdates', value);

  set accent(String value) {
    if (value == _accent && _appearanceUpdatedAt != 0) return;
    _stamp();
    _set(() => _accent = value, 'accent', value);
  }

  set syncAppearance(bool value) =>
      _set(() => _syncAppearance = value, 'syncAccent', value);

  set textScale(double value) {
    final percent = (value * 100).round();
    _set(() => _textScalePercent = percent, 'textScalePercent', percent);
  }

  set soundEnabled(bool value) =>
      _set(() => _soundEnabled = value, 'soundEnabled', value);

  set hapticsEnabled(bool value) =>
      _set(() => _hapticsEnabled = value, 'hapticsEnabled', value);

  set reduceMotion(bool value) =>
      _set(() => _reduceMotion = value, 'reduceMotion', value);

  void setSoundMuted(AppSound sound, {required bool muted}) {
    if (muted) {
      _mutedSounds.add(sound);
    } else {
      _mutedSounds.remove(sound);
    }
    _prefs.setStringList('mutedSounds', [
      for (final item in _mutedSounds) item.name,
    ]);
    notifyListeners();
  }

  void _stamp() {
    _appearanceUpdatedAt = DateTime.now().millisecondsSinceEpoch;
    _prefs.setInt('accentUpdatedAt', _appearanceUpdatedAt);
  }

  /// Takes the accent and theme chosen in another app. Keeps that app's timestamp,
  /// so it is not mistaken for a new choice made here. [mode] is null when the
  /// other app is an older version that only shares its accent.
  void adoptAppearance(String accent, String? mode, int updatedAt) {
    if (!CatppuccinPalette.accents.contains(accent)) return;
    if (updatedAt <= _appearanceUpdatedAt) return;
    _accent = accent;
    if (mode != null) _themeMode = _byName(ThemeMode.values, mode, _themeMode);
    _appearanceUpdatedAt = updatedAt;
    _prefs.setString('accent', accent);
    _prefs.setString('themeMode', _themeMode.name);
    _prefs.setInt('accentUpdatedAt', updatedAt);
    notifyListeners();
  }

  /// Completes once every change so far is saved to disk.
  Future<void> flush() => _prefs.flush();

  void _set(VoidCallback change, String key, Object value) {
    change();
    switch (value) {
      case final bool v:
        _prefs.setBool(key, v);
      case final int v:
        _prefs.setInt(key, v);
      case final String v:
        _prefs.setString(key, v);
    }
    notifyListeners();
  }

  void _importLegacy() {
    final raw = _prefs.getString(_legacyKey);
    if (raw == null) return;
    _prefs.remove(_legacyKey);
    if (_prefs.getString('themeMode') != null) return;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return;
      final follow = json['followSystemTheme'] as bool? ?? true;
      final mode = follow
          ? ThemeMode.system
          : json['themeVariant'] == 'latte'
              ? ThemeMode.light
              : ThemeMode.dark;
      _prefs.setString('themeMode', mode.name);
      _prefs.setString('language', json['language'] as String? ?? L10n.system);
      final scale = (json['textScale'] as num?)?.toDouble() ?? 1.0;
      _prefs.setInt('textScalePercent', (scale * 100).round());
      _prefs.setBool('soundEnabled', json['soundEnabled'] as bool? ?? true);
      _prefs.setBool('hapticsEnabled', json['hapticsEnabled'] as bool? ?? true);
      _prefs.setBool('reduceMotion', json['reduceMotion'] as bool? ?? false);
      final muted = json['mutedSounds'];
      if (muted is List) {
        _prefs.setStringList('mutedSounds', muted.whereType<String>().toList());
      }
    } on Object {
      return;
    }
  }
}
