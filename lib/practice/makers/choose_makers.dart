import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/practice_masks.dart';
import 'package:komak/practice/question.dart';

Question? pickAnswerQuestion(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  int count, {
  int? seconds,
}) {
  return buildChoice(
    kind: kind,
    card: card,
    prompt: card.front,
    options: c.options(
      card,
      read: (Flashcard x) => x.back,
      count: count,
      forbidden: c.validBackKeys(card),
    ),
    correct: card.back,
    seconds: seconds,
  );
}

Question? pickQuestionQuestion(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  int count, {
  int? seconds,
}) {
  return buildChoice(
    kind: kind,
    card: card,
    prompt: card.back,
    options: c.options(
      card,
      read: (Flashcard x) => x.front,
      count: count,
      forbidden: c.validFrontKeys(card),
    ),
    correct: card.front,
    seconds: seconds,
  );
}

Question? _pickReading(PracticeContext c, Flashcard card) {
  final reading = card.reading;
  if (reading == null || !hasText(reading)) return null;
  return buildChoice(
    kind: PracticeKind.pickReading,
    card: card,
    prompt: card.front,
    options: c.options(
      card,
      read: (Flashcard x) => x.reading ?? '',
      count: 4,
      only: (Flashcard x) => hasText(x.reading),
    ),
    correct: reading,
  );
}

Question? _pickByReading(PracticeContext c, Flashcard card) {
  final reading = card.reading;
  if (reading == null || !hasText(reading)) return null;
  final readingKey = textKey(reading);
  final forbidden = <String>{
    for (final x in c.cards)
      if (hasText(x.reading) && textKey(x.reading!) == readingKey)
        textKey(x.front),
  };
  return buildChoice(
    kind: PracticeKind.pickByReading,
    card: card,
    prompt: reading,
    options: c.options(
      card,
      read: (Flashcard x) => x.front,
      count: 4,
      forbidden: forbidden,
    ),
    correct: card.front,
  );
}

Question? _pickGroup(PracticeContext c, Flashcard card) {
  final group = card.groupId ?? '';
  if (group.isEmpty) return null;
  final others = c.groups.where((String g) => g != group).toList()
    ..shuffle(c.random);
  if (others.isEmpty) return null;
  final options = <String>[group, ...others.take(3)]..shuffle(c.random);
  return buildChoice(
    kind: PracticeKind.pickGroup,
    card: card,
    prompt: card.front,
    options: options,
    correct: group,
  );
}

Question? _oddOneOut(PracticeContext c, Flashcard card) {
  final group = card.groupId ?? '';
  if (group.isEmpty) return null;
  final same = c.cards
      .where((Flashcard x) => x.id != card.id && x.groupId == group)
      .toList()
    ..shuffle(c.random);
  final other = c.cards
      .where(
        (Flashcard x) => (x.groupId ?? '').isNotEmpty && x.groupId != group,
      )
      .toList()
    ..shuffle(c.random);
  if (same.length < 2 || other.isEmpty) return null;
  final members = <Flashcard>[card, same[0], same[1]];
  final imposter = other.first;
  final keys = <String>{for (final x in members) textKey(x.front)};
  if (keys.length < 3 || keys.contains(textKey(imposter.front))) return null;
  final options = <String>[
    for (final x in members) x.front,
    imposter.front,
  ]..shuffle(c.random);
  return ChoiceQuestion(
    kind: PracticeKind.oddOneOut,
    cardIds: <String>[card.id, imposter.id],
    instruction: 'Which one does not belong with the others?',
    options: options,
    correct: <int>{options.indexOf(imposter.front)},
    reveal: '${imposter.front} (${imposter.groupId})',
  );
}

Question? _fillBlank(PracticeContext c, Flashcard card) {
  final example = card.example;
  if (example == null || !hasText(example)) return null;
  final blank = blankSentence(example, card.front);
  if (blank == null) return null;
  final lower = example.toLowerCase();
  return buildChoice(
    kind: PracticeKind.fillBlankChoice,
    card: card,
    instruction: 'Fill in the blank',
    prompt: blank,
    options: c.options(
      card,
      read: (Flashcard x) => x.front,
      count: 4,
      only: (Flashcard x) => !lower.contains(x.front.toLowerCase()),
    ),
    correct: card.front,
  );
}

Question? _pickExample(PracticeContext c, Flashcard card) {
  final example = card.example;
  if (example == null || !hasText(example)) return null;
  return buildChoice(
    kind: PracticeKind.pickExample,
    card: card,
    instruction: 'Which sentence uses it?',
    prompt: card.front,
    options: c.options(
      card,
      read: (Flashcard x) => x.example ?? '',
      count: 4,
      only: (Flashcard x) => hasText(x.example),
    ),
    correct: example,
  );
}

Question? _wrongPair(PracticeContext c, Flashcard card) {
  final picks = c.sample(card, 4);
  if (picks == null) return null;
  final lines = <String>[
    for (final x in picks) '${x.front} = ${x.back}',
  ];
  final wrong = '${picks[0].front} = ${picks[1].back}';
  final options = <String>[wrong, lines[1], lines[2], lines[3]]
    ..shuffle(c.random);
  return ChoiceQuestion(
    kind: PracticeKind.wrongPair,
    cardIds: <String>[card.id],
    instruction: 'Which pair is wrong?',
    options: options,
    correct: <int>{options.indexOf(wrong)},
    reveal: lines[0],
  );
}

Question? _pickNext(PracticeContext c, Flashcard card) {
  final i = c.orderedIndex(card);
  if (i < 0 || i + 1 >= c.ordered.length) return null;
  final next = c.ordered[i + 1];
  if (textKey(next.front) == textKey(card.front)) return null;
  return buildChoice(
    kind: PracticeKind.pickNext,
    card: card,
    instruction: 'Which comes right after this?',
    prompt: card.front,
    options: c.options(
      next,
      read: (Flashcard x) => x.front,
      count: 4,
      forbidden: <String>{textKey(card.front)},
    ),
    correct: next.front,
  );
}

Question? _pickPrevious(PracticeContext c, Flashcard card) {
  final i = c.orderedIndex(card);
  if (i < 1) return null;
  final previous = c.ordered[i - 1];
  if (textKey(previous.front) == textKey(card.front)) return null;
  return buildChoice(
    kind: PracticeKind.pickPrevious,
    card: card,
    instruction: 'Which comes right before this?',
    prompt: card.front,
    options: c.options(
      previous,
      read: (Flashcard x) => x.front,
      count: 4,
      forbidden: <String>{textKey(card.front)},
    ),
    correct: previous.front,
  );
}

Question? _pickBetween(PracticeContext c, Flashcard card) {
  final i = c.orderedIndex(card);
  if (i < 1 || i + 1 >= c.ordered.length) return null;
  final before = c.ordered[i - 1];
  final after = c.ordered[i + 1];
  return buildChoice(
    kind: PracticeKind.pickBetween,
    card: card,
    instruction: 'Which comes between these two?',
    prompt: '${before.front}  ·  ${after.front}',
    options: c.options(
      card,
      read: (Flashcard x) => x.front,
      count: 4,
      forbidden: <String>{textKey(before.front), textKey(after.front)},
    ),
    correct: card.front,
  );
}

final Map<PracticeKind, Maker> chooseMakers = <PracticeKind, Maker>{
  PracticeKind.pickAnswer: (PracticeContext c, Flashcard card) =>
      pickAnswerQuestion(c, card, PracticeKind.pickAnswer, 4),
  PracticeKind.pickQuestion: (PracticeContext c, Flashcard card) =>
      pickQuestionQuestion(c, card, PracticeKind.pickQuestion, 4),
  PracticeKind.pickAnswerThree: (PracticeContext c, Flashcard card) =>
      pickAnswerQuestion(c, card, PracticeKind.pickAnswerThree, 3),
  PracticeKind.pickAnswerSix: (PracticeContext c, Flashcard card) =>
      pickAnswerQuestion(c, card, PracticeKind.pickAnswerSix, 6),
  PracticeKind.pickReading: _pickReading,
  PracticeKind.pickByReading: _pickByReading,
  PracticeKind.pickGroup: _pickGroup,
  PracticeKind.oddOneOut: _oddOneOut,
  PracticeKind.fillBlankChoice: _fillBlank,
  PracticeKind.pickExample: _pickExample,
  PracticeKind.wrongPair: _wrongPair,
  PracticeKind.pickNext: _pickNext,
  PracticeKind.pickPrevious: _pickPrevious,
  PracticeKind.pickBetween: _pickBetween,
};
