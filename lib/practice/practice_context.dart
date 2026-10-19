import 'dart:math';

import 'package:komak/core/text_normalizer.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

bool hasText(String? value) => value != null && value.trim().isNotEmpty;

String textKey(String value) {
  final folded = normalizeAnswer(value);
  return folded.isEmpty ? value.trim().toLowerCase() : folded;
}

typedef Maker = Question? Function(PracticeContext ctx, Flashcard card);

class PracticeContext {
  PracticeContext(this.deck, {Random? random})
      : random = random ?? Random(),
        cards = deck.cards,
        ordered = (deck.cards
            .where((Flashcard c) => c.orderIndex != null)
            .toList()
          ..sort(
            (Flashcard a, Flashcard b) => a.orderIndex!.compareTo(b.orderIndex!),
          ));

  final Deck deck;
  final Random random;
  final List<Flashcard> cards;
  final List<Flashcard> ordered;

  T pick<T>(List<T> items) => items[random.nextInt(items.length)];

  List<String> get groups => deck.groups;

  Set<String> validBackKeys(Flashcard card) {
    final key = textKey(card.front);
    return <String>{
      for (final c in cards)
        if (textKey(c.front) == key) textKey(c.back),
    };
  }

  Set<String> validFrontKeys(Flashcard card) {
    final key = textKey(card.back);
    return <String>{
      for (final c in cards)
        if (textKey(c.back) == key) textKey(c.front),
    };
  }

  List<String> backsFor(Flashcard card) {
    final key = textKey(card.front);
    return <String>[
      card.back,
      for (final c in cards)
        if (c.id != card.id && textKey(c.front) == key) c.back,
    ];
  }

  List<String> frontsFor(Flashcard card) {
    final key = textKey(card.back);
    return <String>[
      card.front,
      for (final c in cards)
        if (c.id != card.id && textKey(c.back) == key) c.front,
    ];
  }

  int orderedIndex(Flashcard card) =>
      ordered.indexWhere((Flashcard c) => c.id == card.id);

  List<String>? options(
    Flashcard card, {
    required String Function(Flashcard) read,
    required int count,
    Set<String> forbidden = const <String>{},
    bool Function(Flashcard)? only,
  }) {
    final correct = read(card);
    final taken = <String>{textKey(correct), ...forbidden};
    final group = card.groupId ?? '';
    final pool = cards
        .where(
          (Flashcard c) =>
              c.id != card.id && (only == null || only(c)),
        )
        .toList()
      ..shuffle(random);
    final same = <Flashcard>[];
    final rest = <Flashcard>[];
    for (final c in pool) {
      if (group.isNotEmpty && c.groupId == group) {
        same.add(c);
      } else {
        rest.add(c);
      }
    }
    final chosen = <String>[];
    for (final c in <Flashcard>[...same, ...rest]) {
      if (chosen.length >= count - 1) break;
      final text = read(c);
      if (!hasText(text)) continue;
      if (taken.add(textKey(text))) chosen.add(text);
    }
    if (chosen.length < count - 1) return null;
    return <String>[correct, ...chosen]..shuffle(random);
  }

  List<Flashcard>? sample(
    Flashcard seed,
    int count, {
    bool Function(Flashcard)? where,
    String Function(Flashcard)? distinct,
  }) {
    final pool = cards
        .where(
          (Flashcard c) =>
              c.id != seed.id && (where == null || where(c)),
        )
        .toList()
      ..shuffle(random);
    final fronts = <String>{textKey(seed.front)};
    final backs = <String>{textKey(seed.back)};
    final extras = <String>{if (distinct != null) textKey(distinct(seed))};
    final out = <Flashcard>[seed];
    for (final c in pool) {
      if (out.length >= count) break;
      final frontKey = textKey(c.front);
      final backKey = textKey(c.back);
      if (fronts.contains(frontKey) || backs.contains(backKey)) continue;
      if (distinct != null) {
        final extraKey = textKey(distinct(c));
        if (extras.contains(extraKey)) continue;
        extras.add(extraKey);
      }
      fronts.add(frontKey);
      backs.add(backKey);
      out.add(c);
    }
    return out.length == count ? out : null;
  }

  Flashcard? randomOther(Flashcard card, bool Function(Flashcard) test) {
    final pool =
        cards.where((Flashcard c) => c.id != card.id && test(c)).toList();
    if (pool.isEmpty) return null;
    return pick(pool);
  }
}

ChoiceQuestion? buildChoice({
  required PracticeKind kind,
  required Flashcard card,
  required List<String>? options,
  required String correct,
  String prompt = '',
  String? instruction,
  String? detail,
  String? reveal,
  int? seconds,
  Preview? preview,
  List<String>? cardIds,
}) {
  if (options == null) return null;
  final index = options.indexOf(correct);
  if (index < 0) return null;
  return ChoiceQuestion(
    kind: kind,
    cardIds: cardIds ?? <String>[card.id],
    prompt: prompt,
    instruction: instruction,
    detail: detail,
    options: options,
    correct: <int>{index},
    reveal: reveal ?? correct,
    seconds: seconds,
    preview: preview,
  );
}
