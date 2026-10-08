import 'package:flutter/foundation.dart';
import 'package:komak/core/models/app_settings.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/streak_data.dart';
import 'package:komak/core/services/haptics_service.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/services/storage_service.dart';
import 'package:komak/data/builtin_decks/builtin_decks.dart';

class AppController extends ChangeNotifier {
  AppController(this._storage, this.sound);

  static const int _currentSeedVersion = 3;

  final StorageService _storage;
  final SoundService sound;
  final HapticsService haptics = HapticsService();

  List<Deck> _decks = <Deck>[];
  AppSettings _settings = const AppSettings();
  StreakData _streak = const StreakData();

  List<Deck> get decks => List<Deck>.unmodifiable(_decks);
  AppSettings get settings => _settings;
  StreakData get streak => _streak;

  int get totalCards =>
      _decks.fold(0, (int sum, Deck d) => sum + d.cards.length);

  int get missingBuiltInCount =>
      buildBuiltInDecks().where((Deck b) => !_hasBuiltIn(b.builtInKey)).length;

  Future<void> initialize() async {
    _settings = _storage.loadSettings();
    _streak = _storage.loadStreak();
    sound.enabled = _settings.soundEnabled;
    sound.muted = _settings.mutedSounds;
    haptics.enabled = _settings.hapticsEnabled;
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

    final Set<QuestionType> newTypes = <QuestionType>{
      QuestionType.trueFalse,
      QuestionType.reverseChoice,
      QuestionType.scramble,
      QuestionType.hintTyping,
      QuestionType.selfCheck,
      QuestionType.memory,
    };
    for (final Deck deck in _decks) {
      deck.enabledTypes = <QuestionType>{...deck.enabledTypes, ...newTypes};
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
      deck.practiceLength =
          practiceLength.clamp(minPracticeLength, maxPracticeLength);
    }
    await _persistDecks();
  }

  Future<void> setDeckEnabledTypes(
    String deckId,
    Set<QuestionType> types,
  ) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    deck.enabledTypes = types;
    await _persistDecks();
  }

  Future<void> addCardsToDeck(String deckId, List<Flashcard> cards) async {
    final Deck? deck = deckByIdOrNull(deckId);
    if (deck == null) return;
    deck.cards.addAll(cards);
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
    deck.cards[index].registerAttempt(wasCorrect: wasCorrect);
    await _storage.saveDecks(_decks);
  }

  Future<void> completeSession() async {
    _streak = _streak.registerStudyToday();
    await _storage.saveStreak(_streak);
    await _storage.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> updateSettings(
    AppSettings Function(AppSettings current) transform,
  ) async {
    _settings = transform(_settings);
    sound.enabled = _settings.soundEnabled;
    sound.muted = _settings.mutedSounds;
    haptics.enabled = _settings.hapticsEnabled;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> _persistDecks() async {
    await _storage.saveDecks(_decks);
    notifyListeners();
  }
}
