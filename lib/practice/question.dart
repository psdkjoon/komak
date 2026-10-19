import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/practice_kind.dart';

typedef ResolveCallback = void Function(Set<String> missed, {String? note});

class Preview {
  const Preview({required this.lines, required this.seconds, this.title});

  final List<String> lines;
  final int seconds;
  final String? title;
}

sealed class Question {
  const Question({required this.kind, required this.cardIds});

  final PracticeKind kind;
  final List<String> cardIds;
}

class ChoiceQuestion extends Question {
  const ChoiceQuestion({
    required super.kind,
    required super.cardIds,
    required this.options,
    required this.correct,
    required this.reveal,
    this.prompt = '',
    this.instruction,
    this.detail,
    this.seconds,
    this.selectAll = false,
    this.preview,
  });

  final String prompt;
  final String? instruction;
  final String? detail;
  final List<String> options;
  final Set<int> correct;
  final String reveal;
  final int? seconds;
  final bool selectAll;
  final Preview? preview;
}

class TypeQuestion extends Question {
  const TypeQuestion({
    required super.kind,
    required super.cardIds,
    required this.prompt,
    required this.answers,
    required this.reveal,
    this.instruction,
    this.mask,
    this.tolerant = false,
    this.seconds,
    this.preview,
  });

  final String prompt;
  final String? instruction;
  final String? mask;
  final List<String> answers;
  final String reveal;
  final bool tolerant;
  final int? seconds;
  final Preview? preview;
}

class MatchQuestion extends Question {
  const MatchQuestion({
    required super.kind,
    required super.cardIds,
    required this.left,
    required this.right,
    this.instruction,
  });

  final List<String> left;
  final List<String> right;
  final String? instruction;
}

class ArrangeQuestion extends Question {
  const ArrangeQuestion({
    required super.kind,
    required super.cardIds,
    required this.pieces,
    this.prompt = '',
    this.instruction,
    this.extras = const <String>[],
    this.joiner = ' ',
    this.perPiece = false,
    this.preview,
  });

  final String prompt;
  final String? instruction;
  final List<String> pieces;
  final List<String> extras;
  final String joiner;
  final bool perPiece;
  final Preview? preview;

  String get reveal => pieces.join(joiner);
}

class SortQuestion extends Question {
  const SortQuestion({
    required super.kind,
    required super.cardIds,
    required this.buckets,
    required this.items,
    required this.itemBucket,
    this.instruction,
  });

  final List<String> buckets;
  final List<String> items;
  final List<int> itemBucket;
  final String? instruction;
}

class FlashQuestion extends Question {
  const FlashQuestion({
    required super.kind,
    required super.cardIds,
    required this.prompt,
    required this.answer,
    this.instruction,
    this.details = const <String>[],
    this.thinkSeconds = 0,
  });

  final String prompt;
  final String? instruction;
  final String answer;
  final List<String> details;
  final int thinkSeconds;
}

class MemoryQuestion extends Question {
  const MemoryQuestion({
    required super.kind,
    required super.cardIds,
    required this.left,
    required this.right,
    required this.previewSeconds,
  });

  final List<String> left;
  final List<String> right;
  final int previewSeconds;
}

class MeetQuestion extends Question {
  MeetQuestion(this.card)
      : super(kind: PracticeKind.flashForward, cardIds: <String>[card.id]);

  final Flashcard card;
}
