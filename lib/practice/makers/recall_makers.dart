import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

Question? _flash(
  Flashcard card,
  PracticeKind kind, {
  required String prompt,
  required String answer,
  String? instruction,
  List<String> details = const <String>[],
  int thinkSeconds = 0,
}) {
  return FlashQuestion(
    kind: kind,
    cardIds: <String>[card.id],
    prompt: prompt,
    answer: answer,
    instruction: instruction,
    details: details,
    thinkSeconds: thinkSeconds,
  );
}

Question? _reading(PracticeContext c, Flashcard card) {
  final reading = card.reading;
  if (reading == null || !hasText(reading)) return null;
  return _flash(
    card,
    PracticeKind.flashReading,
    prompt: card.front,
    answer: reading,
    instruction: 'How is it read?',
  );
}

Question? _example(PracticeContext c, Flashcard card) {
  final example = card.example;
  if (example == null || !hasText(example)) return null;
  return _flash(
    card,
    PracticeKind.flashExample,
    prompt: card.front,
    answer: example,
    instruction: 'Say a sentence with it',
  );
}

Question? _full(PracticeContext c, Flashcard card) {
  final details = <String>[
    if (hasText(card.reading)) card.reading!,
    if (hasText(card.example)) card.example!,
    if (hasText(card.note)) card.note!,
    if ((card.groupId ?? '').isNotEmpty) card.groupId!,
  ];
  return _flash(
    card,
    PracticeKind.flashFull,
    prompt: card.front,
    answer: card.back,
    instruction: 'Say everything you know about it',
    details: details,
  );
}

final Map<PracticeKind, Maker> recallMakers = <PracticeKind, Maker>{
  PracticeKind.flashForward: (PracticeContext c, Flashcard card) => _flash(
        card,
        PracticeKind.flashForward,
        prompt: card.front,
        answer: card.back,
      ),
  PracticeKind.flashBackward: (PracticeContext c, Flashcard card) => _flash(
        card,
        PracticeKind.flashBackward,
        prompt: card.back,
        answer: card.front,
      ),
  PracticeKind.flashReading: _reading,
  PracticeKind.flashExample: _example,
  PracticeKind.flashFull: _full,
  PracticeKind.thinkFirst: (PracticeContext c, Flashcard card) => _flash(
        card,
        PracticeKind.thinkFirst,
        prompt: card.front,
        answer: card.back,
        instruction: 'Think about it for a moment',
        thinkSeconds: 5,
      ),
};
