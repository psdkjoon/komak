import 'package:komak/core/text_normalizer.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/practice_masks.dart';
import 'package:komak/practice/question.dart';

TypeQuestion typeAnswerQuestion(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind, {
  bool tolerant = false,
  int? seconds,
  Preview? preview,
}) {
  return TypeQuestion(
    kind: kind,
    cardIds: <String>[card.id],
    prompt: card.front,
    answers: c.backsFor(card),
    reveal: card.back,
    tolerant: tolerant,
    seconds: seconds,
    preview: preview,
  );
}

Question? _typeQuestion(PracticeContext c, Flashcard card) {
  return TypeQuestion(
    kind: PracticeKind.typeQuestion,
    cardIds: <String>[card.id],
    prompt: card.back,
    answers: c.frontsFor(card),
    reveal: card.front,
  );
}

Question? _typeHint(PracticeContext c, Flashcard card) {
  if (normalizeAnswer(card.back).length < 3) return null;
  return TypeQuestion(
    kind: PracticeKind.typeHint,
    cardIds: <String>[card.id],
    prompt: card.front,
    mask: buildAnswerHint(card.back),
    answers: c.backsFor(card),
    reveal: card.back,
  );
}

Question? _typeGaps(PracticeContext c, Flashcard card) {
  final mask = gapMask(card.back, c.random);
  if (mask == null) return null;
  return TypeQuestion(
    kind: PracticeKind.typeGaps,
    cardIds: <String>[card.id],
    prompt: card.front,
    mask: mask,
    answers: c.backsFor(card),
    reveal: card.back,
  );
}

Question? _typeVowels(PracticeContext c, Flashcard card) {
  final mask = vowelMask(card.back);
  if (mask == null) return null;
  return TypeQuestion(
    kind: PracticeKind.typeVowels,
    cardIds: <String>[card.id],
    prompt: card.front,
    mask: mask,
    answers: c.backsFor(card),
    reveal: card.back,
  );
}

Question? _typeCloze(PracticeContext c, Flashcard card) {
  final example = card.example;
  if (example == null || !hasText(example)) return null;
  final blank = blankSentence(example, card.front);
  if (blank == null) return null;
  return TypeQuestion(
    kind: PracticeKind.typeCloze,
    cardIds: <String>[card.id],
    instruction: 'Type the missing word',
    prompt: blank,
    answers: <String>[card.front],
    reveal: card.front,
  );
}

Question? _typeReading(PracticeContext c, Flashcard card) {
  final reading = card.reading;
  if (reading == null || !hasText(reading)) return null;
  return TypeQuestion(
    kind: PracticeKind.typeReading,
    cardIds: <String>[card.id],
    prompt: card.front,
    answers: <String>[reading],
    reveal: reading,
  );
}

Question? _typeFromReading(PracticeContext c, Flashcard card) {
  final reading = card.reading;
  if (reading == null || !hasText(reading)) return null;
  return TypeQuestion(
    kind: PracticeKind.typeFromReading,
    cardIds: <String>[card.id],
    prompt: reading,
    answers: <String>[card.front],
    reveal: card.front,
  );
}

Question? _typeForgiving(PracticeContext c, Flashcard card) {
  if (normalizeAnswer(card.back).length < 5) return null;
  return typeAnswerQuestion(c, card, PracticeKind.typeForgiving, tolerant: true);
}

Question? _typeFixTypo(PracticeContext c, Flashcard card) {
  final typo = typoOf(card.back, c.random);
  if (typo == null || textKey(typo) == textKey(card.back)) return null;
  return TypeQuestion(
    kind: PracticeKind.typeFixTypo,
    cardIds: <String>[card.id],
    instruction: 'This answer has a typo. Type it correctly.',
    prompt: card.front,
    mask: typo,
    answers: c.backsFor(card),
    reveal: card.back,
  );
}

Question? _typeNext(PracticeContext c, Flashcard card) {
  final i = c.orderedIndex(card);
  if (i < 0 || i + 1 >= c.ordered.length) return null;
  final next = c.ordered[i + 1];
  return TypeQuestion(
    kind: PracticeKind.typeNext,
    cardIds: <String>[card.id],
    instruction: 'Type what comes next',
    prompt: card.front,
    answers: <String>[next.front],
    reveal: next.front,
  );
}

Question? _typeGroup(PracticeContext c, Flashcard card) {
  final group = card.groupId ?? '';
  if (group.isEmpty) return null;
  return TypeQuestion(
    kind: PracticeKind.typeGroup,
    cardIds: <String>[card.id],
    instruction: 'Type the group',
    prompt: card.front,
    answers: <String>[group],
    reveal: group,
  );
}

final Map<PracticeKind, Maker> typeMakers = <PracticeKind, Maker>{
  PracticeKind.typeAnswer: (PracticeContext c, Flashcard card) =>
      typeAnswerQuestion(c, card, PracticeKind.typeAnswer),
  PracticeKind.typeQuestion: _typeQuestion,
  PracticeKind.typeHint: _typeHint,
  PracticeKind.typeGaps: _typeGaps,
  PracticeKind.typeVowels: _typeVowels,
  PracticeKind.typeCloze: _typeCloze,
  PracticeKind.typeReading: _typeReading,
  PracticeKind.typeFromReading: _typeFromReading,
  PracticeKind.typeForgiving: _typeForgiving,
  PracticeKind.typeFixTypo: _typeFixTypo,
  PracticeKind.typeNext: _typeNext,
  PracticeKind.typeGroup: _typeGroup,
};
