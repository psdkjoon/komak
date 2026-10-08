import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class ReverseChoiceQuestion extends StudyQuestion {
  const ReverseChoiceQuestion({
    required this.card,
    required this.options,
    required this.correctIndex,
  });

  final Flashcard card;
  final List<String> options;
  final int correctIndex;

  @override
  QuestionType get type => QuestionType.reverseChoice;
}
