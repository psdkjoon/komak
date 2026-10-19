import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/makers/choose_makers.dart';
import 'package:komak/practice/makers/type_makers.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

Question _verdict({
  required PracticeKind kind,
  required Flashcard card,
  required String prompt,
  required String claim,
  required bool isTrue,
  required String reveal,
  String? instruction,
  int? seconds,
}) {
  return ChoiceQuestion(
    kind: kind,
    cardIds: <String>[card.id],
    prompt: prompt,
    instruction: instruction ?? 'Is this correct?',
    detail: claim,
    options: <String>['True'.tr, 'False'.tr],
    correct: <int>{isTrue ? 0 : 1},
    reveal: reveal,
    seconds: seconds,
  );
}

Question? _trueFalse(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind, {
  int? seconds,
}) {
  final isTrue = c.random.nextBool();
  if (isTrue) {
    return _verdict(
      kind: kind,
      card: card,
      prompt: card.front,
      claim: card.back,
      isTrue: true,
      reveal: card.back,
      seconds: seconds,
    );
  }
  final other = c.options(
    card,
    read: (Flashcard x) => x.back,
    count: 2,
    forbidden: c.validBackKeys(card),
  );
  if (other == null) return null;
  final wrong = other.firstWhere((String o) => textKey(o) != textKey(card.back));
  return _verdict(
    kind: kind,
    card: card,
    prompt: card.front,
    claim: wrong,
    isTrue: false,
    reveal: card.back,
    seconds: seconds,
  );
}

Question? _trueFalseField(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind,
  String? Function(Flashcard) read,
) {
  final mine = read(card);
  if (mine == null || !hasText(mine)) return null;
  final isTrue = c.random.nextBool();
  var claim = mine;
  if (!isTrue) {
    final other = c.randomOther(
      card,
      (Flashcard x) =>
          hasText(read(x)) && textKey(read(x)!) != textKey(mine),
    );
    if (other == null) return null;
    claim = read(other)!;
  }
  return _verdict(
    kind: kind,
    card: card,
    prompt: card.front,
    claim: claim,
    isTrue: isTrue,
    reveal: mine,
  );
}

Question? _trueFalseGroup(PracticeContext c, Flashcard card) {
  final mine = card.groupId ?? '';
  if (mine.isEmpty) return null;
  final others = c.groups.where((String g) => g != mine).toList();
  final isTrue = others.isEmpty || c.random.nextBool();
  return _verdict(
    kind: PracticeKind.trueFalseGroup,
    card: card,
    prompt: card.front,
    claim: isTrue ? mine : c.pick(others),
    isTrue: isTrue,
    reveal: mine,
    instruction: 'Is this its group?',
  );
}

Question? _sameGroup(PracticeContext c, Flashcard card) {
  final mine = card.groupId ?? '';
  if (mine.isEmpty) return null;
  final same = c.random.nextBool();
  final other = c.randomOther(
    card,
    (Flashcard x) =>
        (x.groupId ?? '').isNotEmpty &&
        (same ? x.groupId == mine : x.groupId != mine) &&
        textKey(x.front) != textKey(card.front),
  );
  if (other == null) return null;
  return ChoiceQuestion(
    kind: PracticeKind.sameGroup,
    cardIds: <String>[card.id, other.id],
    prompt: '${card.front}  ·  ${other.front}',
    instruction: 'Are these in the same group?',
    options: <String>['Yes'.tr, 'No'.tr],
    correct: <int>{same ? 0 : 1},
    reveal: same ? mine : '$mine / ${other.groupId}',
  );
}

final Map<PracticeKind, Maker> quickMakers = <PracticeKind, Maker>{
  PracticeKind.trueFalse: (PracticeContext c, Flashcard card) =>
      _trueFalse(c, card, PracticeKind.trueFalse),
  PracticeKind.trueFalseGroup: _trueFalseGroup,
  PracticeKind.trueFalseReading: (PracticeContext c, Flashcard card) =>
      _trueFalseField(
        c,
        card,
        PracticeKind.trueFalseReading,
        (Flashcard x) => x.reading,
      ),
  PracticeKind.trueFalseExample: (PracticeContext c, Flashcard card) =>
      _trueFalseField(
        c,
        card,
        PracticeKind.trueFalseExample,
        (Flashcard x) => x.example,
      ),
  PracticeKind.sameGroup: _sameGroup,
  PracticeKind.twoChoice: (PracticeContext c, Flashcard card) =>
      pickAnswerQuestion(c, card, PracticeKind.twoChoice, 2),
  PracticeKind.sprintChoice: (PracticeContext c, Flashcard card) =>
      pickAnswerQuestion(c, card, PracticeKind.sprintChoice, 4, seconds: 7),
  PracticeKind.sprintTrueFalse: (PracticeContext c, Flashcard card) =>
      _trueFalse(c, card, PracticeKind.sprintTrueFalse, seconds: 5),
  PracticeKind.sprintReverse: (PracticeContext c, Flashcard card) =>
      pickQuestionQuestion(c, card, PracticeKind.sprintReverse, 4, seconds: 8),
  PracticeKind.sprintType: (PracticeContext c, Flashcard card) =>
      typeAnswerQuestion(
        c,
        card,
        PracticeKind.sprintType,
        tolerant: true,
        seconds: 15,
      ),
};
