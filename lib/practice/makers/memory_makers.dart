import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/makers/type_makers.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

Question? _memory(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  int count,
  int seconds, {
  bool readings = false,
}) {
  final picks = c.sample(
    card,
    count,
    where: readings ? (Flashcard x) => hasText(x.reading) : null,
    distinct: readings ? (Flashcard x) => x.reading ?? '' : null,
  );
  if (picks == null) return null;
  return MemoryQuestion(
    kind: kind,
    cardIds: <String>[for (final x in picks) x.id],
    left: <String>[for (final x in picks) x.front],
    right: <String>[
      for (final x in picks) readings ? (x.reading ?? '') : x.back,
    ],
    previewSeconds: seconds,
  );
}

Question? _order(PracticeContext c, Flashcard card) {
  final picks = c.sample(card, 4);
  if (picks == null) return null;
  picks.shuffle(c.random);
  final pieces = <String>[for (final x in picks) x.front];
  return ArrangeQuestion(
    kind: PracticeKind.rememberOrder,
    cardIds: <String>[for (final x in picks) x.id],
    instruction: 'Put them in the order you saw',
    pieces: pieces,
    joiner: ' › ',
    perPiece: true,
    preview: Preview(lines: pieces, seconds: 6, title: 'Remember this order'),
  );
}

Question? _vanished(PracticeContext c, Flashcard card) {
  final picks = c.sample(card, 4);
  if (picks == null) return null;
  final used = <String>{for (final x in picks) textKey(x.front)};
  final decoys = <String>[];
  final pool = List<Flashcard>.of(c.cards)..shuffle(c.random);
  for (final x in pool) {
    if (decoys.length >= 3) break;
    if (picks.any((Flashcard p) => p.id == x.id)) continue;
    if (used.add(textKey(x.front))) decoys.add(x.front);
  }
  if (decoys.length < 2) return null;
  final vanished = c.pick(picks);
  final remaining = <String>[
    for (final x in picks)
      if (x.id != vanished.id) x.front,
  ];
  final options = <String>[vanished.front, ...decoys]..shuffle(c.random);
  return ChoiceQuestion(
    kind: PracticeKind.whichVanished,
    cardIds: <String>[vanished.id],
    instruction: 'One item vanished. Which one?',
    detail: remaining.join('  ·  '),
    options: options,
    correct: <int>{options.indexOf(vanished.front)},
    reveal: vanished.front,
    preview: Preview(
      lines: <String>[for (final x in picks) x.front],
      seconds: 7,
      title: 'Remember these',
    ),
  );
}

Question? _spot(PracticeContext c, Flashcard card) {
  final picks = c.sample(card, 3);
  if (picks == null) return null;
  final used = <String>{for (final x in picks) textKey(x.front)};
  final decoys = <String>[];
  final pool = List<Flashcard>.of(c.cards)..shuffle(c.random);
  for (final x in pool) {
    if (decoys.length >= 3) break;
    if (picks.any((Flashcard p) => p.id == x.id)) continue;
    if (used.add(textKey(x.front))) decoys.add(x.front);
  }
  if (decoys.length < 3) return null;
  final seen = <String>[for (final x in picks) x.front];
  final options = <String>[...seen, ...decoys]..shuffle(c.random);
  return ChoiceQuestion(
    kind: PracticeKind.spotSeen,
    cardIds: <String>[for (final x in picks) x.id],
    instruction: 'Select the three you saw',
    options: options,
    correct: <int>{for (final s in seen) options.indexOf(s)},
    reveal: seen.join('  ·  '),
    selectAll: true,
    preview: Preview(lines: seen, seconds: 6, title: 'Remember these'),
  );
}

Preview _peek(Flashcard card) => Preview(
      lines: <String>[card.front, card.back],
      seconds: 4,
      title: 'Remember this',
    );

Question? _peekPick(PracticeContext c, Flashcard card) {
  final options = c.options(
    card,
    read: (Flashcard x) => x.back,
    count: 4,
    forbidden: c.validBackKeys(card),
  );
  return buildChoice(
    kind: PracticeKind.peekThenPick,
    card: card,
    prompt: card.front,
    options: options,
    correct: card.back,
    preview: _peek(card),
  );
}

final Map<PracticeKind, Maker> memoryMakers = <PracticeKind, Maker>{
  PracticeKind.memoryThree: (PracticeContext c, Flashcard card) =>
      _memory(c, card, PracticeKind.memoryThree, 3, 6),
  PracticeKind.memoryFour: (PracticeContext c, Flashcard card) =>
      _memory(c, card, PracticeKind.memoryFour, 4, 9),
  PracticeKind.memoryReading: (PracticeContext c, Flashcard card) =>
      _memory(c, card, PracticeKind.memoryReading, 4, 7, readings: true),
  PracticeKind.rememberOrder: _order,
  PracticeKind.whichVanished: _vanished,
  PracticeKind.spotSeen: _spot,
  PracticeKind.peekThenPick: _peekPick,
  PracticeKind.peekThenType: (PracticeContext c, Flashcard card) =>
      typeAnswerQuestion(
        c,
        card,
        PracticeKind.peekThenType,
        preview: _peek(card),
      ),
};
