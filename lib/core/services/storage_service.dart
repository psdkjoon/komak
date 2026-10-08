import 'dart:convert';

import 'package:komak/core/models/app_settings.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/streak_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._preferences);

  static const String _decksKey = 'komak_decks_v1';
  static const String _settingsKey = 'komak_settings_v1';
  static const String _streakKey = 'komak_streak_v1';
  static const String _legacySeededKey = 'komak_seeded_v1';
  static const String _seedVersionKey = 'komak_seed_version';

  final SharedPreferences _preferences;

  static Future<StorageService> create() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return StorageService(preferences);
  }

  bool get legacySeeded => _preferences.getBool(_legacySeededKey) ?? false;

  int get seedVersion => _preferences.getInt(_seedVersionKey) ?? 0;

  Future<void> setSeedVersion(int version) async {
    await _preferences.setInt(_seedVersionKey, version);
  }

  List<Deck> loadDecks() {
    final String? raw = _preferences.getString(_decksKey);
    if (raw == null || raw.isEmpty) return <Deck>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Deck.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Deck>[];
    }
  }

  Future<void> saveDecks(List<Deck> decks) async {
    final String encoded =
        jsonEncode(decks.map((Deck d) => d.toJson()).toList());
    await _preferences.setString(_decksKey, encoded);
  }

  AppSettings loadSettings() {
    final String? raw = _preferences.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  StreakData loadStreak() {
    final String? raw = _preferences.getString(_streakKey);
    if (raw == null || raw.isEmpty) return const StreakData();
    try {
      return StreakData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const StreakData();
    }
  }

  Future<void> saveStreak(StreakData streak) async {
    await _preferences.setString(_streakKey, jsonEncode(streak.toJson()));
  }
}
