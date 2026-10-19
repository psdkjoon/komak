import 'dart:math';

import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

MatchQuestion? matchPairsQuestion(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  int count, {
  bool reverse = false,
}) {
  final picks = c.sample(card, count);
  if (picks == null) return null;
  final fronts = <String>[for (final x in picks) x.front];
  final backs = <String>[for (final x in picks) x.back];
  return MatchQuestion(
    kind: kind,
    cardIds: <String>[for (final x in picks) x.id],
    left: reverse ? backs : fronts,
    right: reverse ? fronts : backs,
  );
}

Question? _matchReadings(PracticeContext c, Flashcard card) {
  if (!hasText(card.reading)) return null;
  final picks = c.sample(
    card,
    4,
    where: (Flashcard x) => hasText(x.reading),
    distinct: (Flashcard x) => x.reading ?? '',
  );
  if (picks == null) return null;
  return MatchQuestion(
    kind: PracticeKind.matchReadings,
    cardIds: <String>[for (final x in picks) x.id],
    left: <String>[for (final x in picks) x.front],
    right: <String>[for (final x in picks) x.reading ?? ''],
  );
}

Question? _matchExamples(PracticeContext c, Flashcard card) {
  if (!hasText(card.example)) return null;
  final picks = c.sample(
    card,
    3,
    where: (Flashcard x) => hasText(x.example),
    distinct: (Flashcard x) => x.example ?? '',
  );
  if (picks == null) return null;
  return MatchQuestion(
    kind: PracticeKind.matchExamples,
    cardIds: <String>[for (final x in picks) x.id],
    left: <String>[for (final x in picks) x.front],
    right: <String>[for (final x in picks) x.example ?? ''],
  );
}

Question? _sort(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  int groupsWanted,
) {
  final mine = card.groupId ?? '';
  if (mine.isEmpty) return null;
  final byGroup = <String, List<Flashcard>>{};
  for (final x in c.cards) {
    final group = x.groupId ?? '';
    if (group.isEmpty) continue;
    byGroup.putIfAbsent(group, () => <Flashcard>[]).add(x);
  }
  final ownCards = byGroup[mine];
  if (ownCards == null || ownCards.length < 2) return null;
  final eligible = byGroup.entries
      .where(
        (MapEntry<String, List<Flashcard>> e) =>
            e.key != mine && e.value.length >= 2,
      )
      .map((MapEntry<String, List<Flashcard>> e) => e.key)
      .toList()
    ..shuffle(c.random);
  if (eligible.length < groupsWanted - 1) return null;
  final chosen = <String>[mine, ...eligible.take(groupsWanted - 1)];
  final entries = <(Flashcard, int)>[];
  final seen = <String>{};
  for (var b = 0; b < chosen.length; b++) {
    final pool = List<Flashcard>.of(byGroup[chosen[b]]!)..shuffle(c.random);
    if (b == 0) {
      pool
        ..removeWhere((Flashcard x) => x.id == card.id)
        ..insert(0, card);
    }
    var taken = 0;
    for (final x in pool) {
      if (taken >= 3) break;
      if (!seen.add(textKey(x.front))) continue;
      entries.add((x, b));
      taken += 1;
    }
    if (taken < 2) return null;
  }
  entries.shuffle(c.random);
  return SortQuestion(
    kind: kind,
    cardIds: <String>[for (final e in entries) e.$1.id],
    instruction: 'Sort each item into its group',
    buckets: chosen,
    items: <String>[for (final e in entries) e.$1.front],
    itemBucket: <int>[for (final e in entries) e.$2],
  );
}

Question? _order(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  int wanted,
) {
  final i = c.orderedIndex(card);
  if (i < 0) return null;
  final size = min(wanted, c.ordered.length);
  if (size < 3) return null;
  final start =
      (i - c.random.nextInt(size)).clamp(0, c.ordered.length - size);
  final window = c.ordered.sublist(start, start + size);
  final keys = <String>{for (final x in window) textKey(x.front)};
  if (keys.length != window.length) return null;
  return ArrangeQuestion(
    kind: kind,
    cardIds: <String>[for (final x in window) x.id],
    instruction: 'Put these in the correct order',
    pieces: <String>[for (final x in window) x.front],
    joiner: ' › ',
    perPiece: true,
  );
}

final Map<PracticeKind, Maker> connectMakers = <PracticeKind, Maker>{
  PracticeKind.matchThree: (PracticeContext c, Flashcard card) =>
      matchPairsQuestion(c, card, PracticeKind.matchThree, 3),
  PracticeKind.matchFour: (PracticeContext c, Flashcard card) =>
      matchPairsQuestion(c, card, PracticeKind.matchFour, 4),
  PracticeKind.matchSix: (PracticeContext c, Flashcard card) =>
      matchPairsQuestion(c, card, PracticeKind.matchSix, 6),
  PracticeKind.matchReverse: (PracticeContext c, Flashcard card) =>
      matchPairsQuestion(
        c,
        card,
        PracticeKind.matchReverse,
        4,
        reverse: true,
      ),
  PracticeKind.matchReadings: _matchReadings,
  PracticeKind.matchExamples: _matchExamples,
  PracticeKind.sortGroups: (PracticeContext c, Flashcard card) =>
      _sort(c, card, PracticeKind.sortGroups, 2),
  PracticeKind.sortThreeGroups: (PracticeContext c, Flashcard card) =>
      _sort(c, card, PracticeKind.sortThreeGroups, 3),
  PracticeKind.orderSequence: (PracticeContext c, Flashcard card) =>
      _order(c, card, PracticeKind.orderSequence, 5),
  PracticeKind.orderShort: (PracticeContext c, Flashcard card) =>
      _order(c, card, PracticeKind.orderShort, 3),
};
