import 'package:flutter/foundation.dart';
import 'package:komak/core/card_intake.dart';
import 'package:komak/core/srs.dart';
import 'package:komak/decks/app_store.dart';
import 'package:komak/decks/builtin_decks/builtin_decks.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/decks/streak_data.dart';
import 'package:komak/decks/study_stats.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/settings/app_settings.dart';

class AppController extends ChangeNotifier {
  AppController(this._storage, this.settings) {
    settings.addListener(notifyListeners);
  }

  static const int _currentSeedVersion = 3;

  final AppStore _storage;
  final AppSettings settings;

  List<Deck> _decks = <Deck>[];
  StreakData _streak = const StreakData();
  StudyStats _stats = StudyStats();

  List<Deck> get decks => List<Deck>.unmodifiable(_decks);
  StreakData get streak => _streak;
  StudyStats get stats => _stats;

  int get totalDue => _decks.fold(0, (int sum, Deck d) => sum + d.dueCount);

  int get totalCards =>
      _decks.fold(0, (int sum, Deck d) => sum + d.cards.length);

  int get missingBuiltInCount =>
      buildBuiltInDecks().where((Deck b) => !_hasBuiltIn(b.builtInKey)).length;

  Future<void> initialize() async {
    _streak = _storage.loadStreak();
    _stats = _storage.loadStats();
    _decks = _storage.loadDecks();
    await _migrate();
    notifyListeners();
  }

  Future<void> _migrate() async {
    final int version = _storage.seedVersion;
    if (version >= _currentSeedVersion) return;

    if (version < 2) {
      if (_storage.legacySeeded) {
        _decks.removeWhere((Deck d) => d.builtInKey == 'imposter');
        final int capitalsIndex =
            _decks.indexWhere((Deck d) => d.builtInKey == 'capitals');
        if (capitalsIndex != -1 && _decks[capitalsIndex].cards.length < 100) {
          _decks[capitalsIndex] = buildBuiltInDeckByKey('capitals')!;
        }
      } else if (_decks.isEmpty) {
        _decks.addAll(buildBuiltInDecks());
      }
    }

    final int monthsIndex =
        _decks.indexWhere((Deck d) => d.builtInKey == 'months');
    if (monthsIndex != -1) {
      _decks.removeAt(monthsIndex);
      _decks.insertAll(monthsIndex, <Deck>[
        buildBuiltInDeckByKey('month-days')!,
        buildBuiltInDeckByKey('month-order')!,
      ]);
    }

    await _storage.setSeedVersion(_currentSeedVersion);
    await _storage.saveDecks(_decks);
  }

  bool _hasBuiltIn(String? key) => _decks.any((Deck d) => d.builtInKey == key);

  Deck? deckByIdOrNull(String id) {
    for (final Deck deck in _decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  Deck deckById(String id) => _decks.firstWhere((Deck d) => d.id == id);

  Future<void> addDeck(Deck deck) async {
    _decks.add(deck);
    await _persistDecks();
  }

  Future<void> insertDeck(int index, Deck deck) async {
    final int safeIndex = index.clamp(0, _decks.length);
    _decks.insert(safeIndex, deck);
    await _persistDecks();
  }

  int indexOfDeck(String deckId) =>
      _decks.indexWhere((Deck d) => d.id == deckId);

  Future<void> deleteDeck(String deckId) async {
    _decks.removeWhere((Deck d) => d.id == deckId);
    await _persistDecks();
  }

  Future<Map<int, Deck>> deleteDecks(Set<String> deckIds) async {
    final Map<int, Deck> removed = <int, Deck>{};
    for (int i = 0; i < _decks.length; i++) {
      if (deckIds.contains(_decks[i].id)) removed[i] = _decks[i];
    }
    if (removed.isEmpty) return removed;
    _decks.removeWhere((Deck d) => deckIds.contains(d.id));
    await _persistDecks();
    return removed;
  }

  Future<void> restoreDecks(Map<int, Deck> decksByIndex) async {
    final List<int> indexes = decksByIndex.keys.toList()..sort();
    for (final int index in indexes) {
      _decks.insert(index.clamp(0, _decks.length), decksByIndex[index]!);
    }
    await _persistDecks();
  }

  Future<void> moveDecks(Set<String> deckIds, int delta) async {
    if (delta < 0) {
      for (int i = 1; i < _decks.length; i++) {
        if (deckIds.contains(_decks[i].id) &&
            !deckIds.contains(_decks[i - 1].id)) {
          final Deck deck = _decks.removeAt(i);
          _decks.insert(i - 1, deck);
        }
      }
    } else if (delta > 0) {
      for (int i = _decks.length - 2; i >= 0; i--) {
        if (deckIds.contains(_decks[i].id) &&
            !deckIds.contains(_decks[i + 1].id)) {
          final Deck deck = _decks.removeAt(i);
          _decks.insert(i + 1, deck);
        }
      }
    }
    await _persistDecks();
  }

  Future<void> moveDecksToEdge(
    Set<String> deckIds, {
    required bool toStart,
  }) async {
    final List<Deck> picked =
        _decks.where((Deck d) => deckIds.contains(d.id)).toList();
    final List<Deck> rest =
        _decks.where((Deck d) => !deckIds.contains(d.id)).toList();
    _decks = toStart ? <Deck>[...picked, ...rest] : <Deck>[...rest, ...picked];
    await _persistDecks();
  }

  Future<void> setDecksColor(Set<String> deckIds, int colorValue) async {
    for (final Deck deck in _decks) {
      if (deckIds.contains(deck.id)) deck.accentColorValue = colorValue;
    }
    await _persistDecks();
  }

  Future<int> restoreBuiltInDecks() async {
    int restored = 0;
    for (final Deck builtIn in buildBuiltInDecks()) {
      if (!_hasBuiltIn(builtIn.builtInKey)) {
        _decks.add(builtIn);
        restored += 1;
      }
    }
    if (restored > 0) await _persistDecks();
    return restored;
  }

  Future<void> updateDeck(
    String deckId, {
    String? title,
    String? description,
    int? accentColorValue,
    String? iconKey,
    int? practiceLength,
  }) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    if (title != null) deck.title = title;
    if (description != null) deck.description = description;
    if (accentColorValue != null) deck.accentColorValue = accentColorValue;
    if (iconKey != null) deck.iconKey = iconKey;
    if (practiceLength != null) {
      deck.practiceLength = clampPracticeLength(practiceLength);
    }
    await _persistDecks();
  }

  Future<void> setDeckEnabledKinds(
    String deckId,
    Set<PracticeKind> kinds,
  ) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    deck.enabledKinds = kinds;
    await _persistDecks();
  }

  Future<CardIntake> addCardsToDeck(String deckId, List<Flashcard> cards) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) {
      return CardIntake(
        accepted: const <Flashcard>[],
        duplicates: 0,
        overflow: cards.length,
      );
    }
    final CardIntake intake = CardIntake.prepare(deck.cards, cards);
    if (intake.accepted.isNotEmpty) {
      deck.cards.addAll(intake.accepted);
      await _persistDecks();
    }
    return intake;
  }

  bool isDuplicateCard(String deckId, Flashcard card) {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return false;
    final String key = cardKey(card);
    return deck.cards.any((Flashcard c) => c.id != card.id && cardKey(c) == key);
  }

  Future<int> removeDuplicateCards(String deckId) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return 0;
    final Set<String> seen = <String>{};
    final List<Flashcard> kept = <Flashcard>[];
    for (final Flashcard card in deck.cards) {
      if (seen.add(cardKey(card))) kept.add(card);
    }
    final int removed = deck.cards.length - kept.length;
    if (removed > 0) {
      deck.cards = kept;
      await _persistDecks();
    }
    return removed;
  }

  Future<Map<int, Flashcard>> deleteCards(
    String deckId,
    Set<String> cardIds,
  ) async {
    final Map<int, Flashcard> removed = <int, Flashcard>{};
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return removed;
    for (int i = 0; i < deck.cards.length; i++) {
      if (cardIds.contains(deck.cards[i].id)) removed[i] = deck.cards[i];
    }
    if (removed.isEmpty) return removed;
    deck.cards.removeWhere((Flashcard c) => cardIds.contains(c.id));
    await _persistDecks();
    return removed;
  }

  Future<void> restoreCards(
    String deckId,
    Map<int, Flashcard> cardsByIndex,
  ) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    final List<int> indexes = cardsByIndex.keys.toList()..sort();
    for (final int index in indexes) {
      deck.cards.insert(index.clamp(0, deck.cards.length), cardsByIndex[index]!);
    }
    await _persistDecks();
  }

  Future<void> setCardsGroup(
    String deckId,
    Set<String> cardIds,
    String? group,
  ) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    final String clean = (group ?? '').trim();
    for (int i = 0; i < deck.cards.length; i++) {
      if (!cardIds.contains(deck.cards[i].id)) continue;
      deck.cards[i] = clean.isEmpty
          ? deck.cards[i].copyWith(clearGroup: true)
          : deck.cards[i].copyWith(groupId: clean);
    }
    await _persistDecks();
  }

  Future<void> resetCardProgress(String deckId, Set<String> cardIds) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    for (final Flashcard card in deck.cards) {
      if (!cardIds.contains(card.id)) continue;
      card
        ..reps = 0
        ..intervalDays = 0
        ..lapses = 0
        ..ease = Flashcard.defaultEase
        ..dueAt = null;
    }
    await _persistDecks();
  }

  Future<void> updateCard(String deckId, Flashcard updatedCard) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    final int index =
        deck.cards.indexWhere((Flashcard c) => c.id == updatedCard.id);
    if (index != -1) {
      deck.cards[index] = updatedCard;
      await _persistDecks();
    }
  }

  Future<void> insertCard(String deckId, int index, Flashcard card) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    deck.cards.insert(index.clamp(0, deck.cards.length), card);
    await _persistDecks();
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    deck.cards.removeWhere((Flashcard c) => c.id == cardId);
    await _persistDecks();
  }

  Future<void> registerCardAttempt(
    String deckId,
    String cardId, {
    required bool wasCorrect,
  }) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    final int index = deck.cards.indexWhere((Flashcard c) => c.id == cardId);
    if (index == -1) return;
    final Flashcard card = deck.cards[index];
    final bool wasNew = card.isNew;
    card.registerAttempt(wasCorrect: wasCorrect);
    Srs.practice(card, correct: wasCorrect);
    _stats.record(correct: wasCorrect, learned: wasNew && !card.isNew);
    await _storage.saveDecks(_decks);
    await _storage.saveStats(_stats);
  }

  Future<void> registerCardAttempts(
    String deckId,
    Map<String, bool> outcomes,
  ) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null || outcomes.isEmpty) return;
    for (final MapEntry<String, bool> entry in outcomes.entries) {
      final int index = deck.cards.indexWhere((Flashcard c) => c.id == entry.key);
      if (index == -1) continue;
      final Flashcard card = deck.cards[index];
      final bool wasNew = card.isNew;
      card.registerAttempt(wasCorrect: entry.value);
      Srs.practice(card, correct: entry.value);
      _stats.record(correct: entry.value, learned: wasNew && !card.isNew);
    }
    await _storage.saveDecks(_decks);
    await _storage.saveStats(_stats);
  }

  Future<void> reviewCard(
    String deckId,
    String cardId,
    Rating rating,
  ) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    final int index = deck.cards.indexWhere((Flashcard c) => c.id == cardId);
    if (index == -1) return;
    final Flashcard card = deck.cards[index];
    final bool wasNew = card.isNew;
    final bool correct = rating != Rating.again;
    card.registerAttempt(wasCorrect: correct);
    Srs.review(card, rating);
    _stats.record(correct: correct, learned: wasNew && !card.isNew);
    await _storage.saveDecks(_decks);
    await _storage.saveStats(_stats);
  }

  Future<void> completeSession() async {
    _streak = _streak.registerStudyToday();
    await _storage.saveStreak(_streak);
    await _storage.saveStats(_stats);
    await _storage.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> _persistDecks() async {
    await _storage.saveDecks(_decks);
    notifyListeners();
  }
}
