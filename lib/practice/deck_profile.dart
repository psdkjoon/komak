import 'package:komak/core/text_normalizer.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_kind.dart';

class DeckProfile {
  DeckProfile._({
    required this.count,
    required this.distinctFronts,
    required this.distinctBacks,
    required this.groupCount,
    required this.groupedCards,
    required this.ordered,
    required this.readings,
    required this.examples,
    required this.clozes,
    required this.phrases,
    required this.words,
    required this.frontWords,
    required this.longWords,
  });

  final int count;
  final int distinctFronts;
  final int distinctBacks;
  final int groupCount;
  final int groupedCards;
  final int ordered;
  final int readings;
  final int examples;
  final int clozes;
  final int phrases;
  final int words;
  final int frontWords;
  final int longWords;

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  static RegExp? clozePattern(String front) {
    final trimmed = front.trim();
    if (trimmed.isEmpty) return null;
    return RegExp(
      '(?<![\\p{L}\\p{N}])${RegExp.escape(trimmed)}(?![\\p{L}\\p{N}])',
      unicode: true,
      caseSensitive: false,
    );
  }

  static bool isCloze(Flashcard card) {
    final example = card.example;
    if (!_has(example)) return false;
    return clozePattern(card.front)?.hasMatch(example!) ?? false;
  }

  static int wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;

  static bool isLongWord(String text) {
    final normalized = normalizeAnswer(text);
    return normalized.length >= 6 &&
        normalized.length <= 14 &&
        !normalized.contains(' ');
  }

  factory DeckProfile.of(List<Flashcard> cards) {
    final fronts = <String>{};
    final backs = <String>{};
    final groups = <String>{};
    var grouped = 0;
    var ordered = 0;
    var readings = 0;
    var examples = 0;
    var clozes = 0;
    var phrases = 0;
    var words = 0;
    var frontWords = 0;
    var longWords = 0;
    for (final card in cards) {
      fronts.add(normalizeAnswer(card.front));
      backs.add(normalizeAnswer(card.back));
      final group = card.groupId ?? '';
      if (group.isNotEmpty) {
        groups.add(group);
        grouped += 1;
      }
      if (card.orderIndex != null) ordered += 1;
      if (_has(card.reading)) readings += 1;
      if (_has(card.example)) examples += 1;
      if (isCloze(card)) clozes += 1;
      final backWords = wordCount(card.back);
      if (backWords >= 3 && backWords <= 9) phrases += 1;
      if (isScrambleWord(card.back)) words += 1;
      if (isScrambleWord(card.front)) frontWords += 1;
      if (isLongWord(card.back)) longWords += 1;
    }
    return DeckProfile._(
      count: cards.length,
      distinctFronts: fronts.length,
      distinctBacks: backs.length,
      groupCount: groups.length,
      groupedCards: grouped,
      ordered: ordered,
      readings: readings,
      examples: examples,
      clozes: clozes,
      phrases: phrases,
      words: words,
      frontWords: frontWords,
      longWords: longWords,
    );
  }

  bool has(Need need) {
    switch (need) {
      case Need.any:
        return count >= 1;
      case Need.three:
        return distinctFronts >= 3 && distinctBacks >= 3;
      case Need.four:
        return distinctFronts >= 4 && distinctBacks >= 4;
      case Need.six:
        return distinctFronts >= 6 && distinctBacks >= 6;
      case Need.groups:
        return groupCount >= 2 && groupedCards >= 4;
      case Need.threeGroups:
        return groupCount >= 3 && groupedCards >= 6;
      case Need.order:
        return ordered >= 3;
      case Need.reading:
        return readings >= 4;
      case Need.example:
        return examples >= 4;
      case Need.cloze:
        return clozes >= 1 && distinctFronts >= 4;
      case Need.phrase:
        return phrases >= 1;
      case Need.word:
        return words >= 1;
      case Need.frontWord:
        return frontWords >= 1;
      case Need.longWord:
        return longWords >= 1;
    }
  }

  bool supports(PracticeKind kind) => has(kind.need);
}
