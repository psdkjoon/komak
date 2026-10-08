import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class SelfCheckQuestion extends StudyQuestion {
  const SelfCheckQuestion({required this.card});

  final Flashcard card;

  @override
  QuestionType get type => QuestionType.selfCheck;
}
