import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/utils/text_normalizer.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

const int defaultPracticeLength = 10;
const int minPracticeLength = 3;
const int maxPracticeLength = 60;

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
    Set<QuestionType>? enabledTypes,
    this.builtInKey,
    this.practiceLength = defaultPracticeLength,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        cards = cards ?? <Flashcard>[],
        enabledTypes =
            enabledTypes ?? Set<QuestionType>.of(QuestionType.values),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String description;
  int accentColorValue;
  String iconKey;
  List<Flashcard> cards;
  Set<QuestionType> enabledTypes;
  final String? builtInKey;
  int practiceLength;
  final DateTime createdAt;

  bool get isBuiltIn => builtInKey != null;

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

  bool isTypeAvailable(QuestionType type) {
    switch (type) {
      case QuestionType.textField:
        return cards.isNotEmpty;
      case QuestionType.multipleChoice:
      case QuestionType.timed:
      case QuestionType.matching:
        return cards.length >= 4;
      case QuestionType.order:
        return isOrderable;
      case QuestionType.oddOneOut:
        return hasGroups;
      case QuestionType.trueFalse:
        return cards.length >= 3 && distinctBackCount >= 2;
      case QuestionType.reverseChoice:
        return cards.length >= 4 && cards.where(_isUniqueBack).length >= 4;
      case QuestionType.scramble:
        return cards.any((Flashcard c) => isScrambleWord(c.back));
      case QuestionType.hintTyping:
      case QuestionType.selfCheck:
        return cards.isNotEmpty;
      case QuestionType.memory:
        return distinctBackCount >= 4;
    }
  }

  List<QuestionType> get playableTypes {
    return QuestionType.values
        .where(
          (QuestionType t) => enabledTypes.contains(t) && isTypeAvailable(t),
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
      'enabledTypes': enabledTypes.map((QuestionType t) => t.name).toList(),
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
    final Set<QuestionType> types =
        (json['enabledTypes'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => QuestionType.tryParse(e as String))
            .whereType<QuestionType>()
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
      enabledTypes: types.isEmpty ? null : types,
      builtInKey: builtInKey,
      practiceLength: (json['practiceLength'] as int? ?? defaultPracticeLength)
          .clamp(minPracticeLength, maxPracticeLength),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
    );
  }
}
