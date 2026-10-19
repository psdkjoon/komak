import 'dart:convert';

import 'package:komak/core/kv_store.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/streak_data.dart';
import 'package:komak/decks/study_stats.dart';

class AppStore {
  AppStore(this._preferences);

  static const String _decksKey = 'komak_decks_v1';
  static const String _streakKey = 'komak_streak_v1';
  static const String _statsKey = 'komak_stats_v1';
  static const String _legacySeededKey = 'komak_seeded_v1';
  static const String _seedVersionKey = 'komak_seed_version';

  final KvStore _preferences;

  bool get legacySeeded => _preferences.getBool(_legacySeededKey) ?? false;

  int get seedVersion => _preferences.getInt(_seedVersionKey) ?? 0;

  Future<void> setSeedVersion(int version) async {
    _preferences.setInt(_seedVersionKey, version);
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
    _preferences.setString(_decksKey, encoded);
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
    _preferences.setString(_streakKey, jsonEncode(streak.toJson()));
  }

  StudyStats loadStats() {
    final String? raw = _preferences.getString(_statsKey);
    if (raw == null || raw.isEmpty) return StudyStats();
    try {
      return StudyStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return StudyStats();
    }
  }

  Future<void> saveStats(StudyStats stats) async {
    _preferences.setString(_statsKey, jsonEncode(stats.toJson()));
  }
}
