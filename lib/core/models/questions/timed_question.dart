import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class TimedQuestion extends StudyQuestion {
  const TimedQuestion({
    required this.card,
    required this.options,
    required this.correctIndex,
    this.durationSeconds = 7,
  });

  final Flashcard card;
  final List<String> options;
  final int correctIndex;
  final int durationSeconds;

  @override
  QuestionType get type => QuestionType.timed;
}
