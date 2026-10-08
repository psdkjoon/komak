import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class TrueFalseQuestion extends StudyQuestion {
  const TrueFalseQuestion({
    required this.card,
    required this.shownAnswer,
    required this.isTrue,
  });

  final Flashcard card;
  final String shownAnswer;
  final bool isTrue;

  @override
  QuestionType get type => QuestionType.trueFalse;
}
