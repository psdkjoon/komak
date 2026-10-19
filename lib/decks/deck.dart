import 'package:flutter/material.dart';
import 'package:komak/core/card_intake.dart';
import 'package:komak/core/id_generator.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/deck_profile.dart';
import 'package:komak/practice/practice_kind.dart';

const int defaultPracticeLength = 10;
const int minPracticeLength = 3;
const int maxPracticeLength = 500;
const int endlessPractice = 0;

int clampPracticeLength(int value) =>
    value == endlessPractice ? endlessPractice : value.clamp(minPracticeLength, maxPracticeLength);

const Map<String, String> _legacyBuiltInKeys = <String, String>{
  'Months Of The Year': 'months',
  'World Capitals': 'capitals',
  'Spot The Imposter': 'imposter',
};

class Deck {
  Deck({
    String? id,
    required this.title,
    required this.description,
    required this.accentColorValue,
    required this.iconKey,
    List<Flashcard>? cards,
    Set<PracticeKind>? enabledKinds,
    this.builtInKey,
    this.practiceLength = defaultPracticeLength,
    DateTime? createdAt,
  })  : id = id ?? IdGenerator.next(),
        cards = cards ?? <Flashcard>[],
        enabledKinds = enabledKinds ?? Set<PracticeKind>.of(PracticeKind.values),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String description;
  int accentColorValue;
  String iconKey;
  List<Flashcard> cards;
  Set<PracticeKind> enabledKinds;
  final String? builtInKey;
  int practiceLength;
  final DateTime createdAt;

  bool get isBuiltIn => builtInKey != null;

  bool get isFull => cards.length >= maxCardsPerDeck;

  int get dueCount => cards.where((Flashcard c) => c.isDue()).length;

  int get newCount => cards.where((Flashcard c) => c.isNew).length;

  int countStage(CardStage stage) =>
      cards.where((Flashcard c) => c.stage == stage).length;

  List<String> get groups {
    final Set<String> found = <String>{};
    for (final Flashcard card in cards) {
      final String group = card.groupId ?? '';
      if (group.isNotEmpty) found.add(group);
    }
    return found.toList();
  }

  Map<String, int> get groupCounts {
    final Map<String, int> counts = <String, int>{};
    for (final Flashcard card in cards) {
      final String group = card.groupId ?? '';
      if (group.isNotEmpty) counts[group] = (counts[group] ?? 0) + 1;
    }
    return counts;
  }

  Color get accentColor => Color(accentColorValue);

  bool get isOrderable =>
      cards.where((Flashcard c) => c.orderIndex != null).length >= 3;

  bool get hasGroups {
    final Set<String> groups = cards
        .map((Flashcard c) => c.groupId ?? '')
        .where((String g) => g.isNotEmpty)
        .toSet();
    return groups.length >= 2 && cards.length >= 4;
  }

  int get distinctBackCount =>
      cards.map((Flashcard c) => c.back).toSet().length;

  bool _isUniqueBack(Flashcard card) =>
      cards.where((Flashcard c) => c.back == card.back).length == 1;

  bool hasUniqueBack(Flashcard card) => _isUniqueBack(card);

  List<PracticeKind> get playableKinds {
    final DeckProfile profile = DeckProfile.of(cards);
    return PracticeKind.values
        .where(
          (PracticeKind k) => enabledKinds.contains(k) && profile.supports(k),
        )
        .toList();
  }

  int get totalAttempts =>
      cards.fold(0, (int sum, Flashcard c) => sum + c.timesShown);

  double get overallAccuracy {
    final int shown = totalAttempts;
    if (shown == 0) return 0;
    final int correct =
        cards.fold(0, (int sum, Flashcard c) => sum + c.timesCorrect);
    return correct / shown;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'accentColorValue': accentColorValue,
      'iconKey': iconKey,
      'cards': cards.map((Flashcard c) => c.toJson()).toList(),
      'enabledKinds': enabledKinds.map((PracticeKind k) => k.name).toList(),
      'builtInKey': builtInKey,
      'practiceLength': practiceLength,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    final String title = json['title'] as String? ?? 'Untitled deck';
    final bool legacyBuiltIn = json['isBuiltIn'] as bool? ?? false;
    final String? builtInKey = json['builtInKey'] as String? ??
        (legacyBuiltIn ? _legacyBuiltInKeys[title] : null);
    final Set<PracticeKind> kinds =
        (json['enabledKinds'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => PracticeKind.tryParse(e as String))
            .whereType<PracticeKind>()
            .toSet();

    return Deck(
      id: json['id'] as String?,
      title: title,
      description: json['description'] as String? ?? '',
      accentColorValue: json['accentColorValue'] as int? ?? 0xFFCBA6F7,
      iconKey: json['iconKey'] as String? ?? 'style',
      cards: (json['cards'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList(),
      enabledKinds: kinds.isEmpty ? null : kinds,
      builtInKey: builtInKey,
      practiceLength: clampPracticeLength(
        json['practiceLength'] as int? ?? defaultPracticeLength,
      ),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
    );
  }
}
