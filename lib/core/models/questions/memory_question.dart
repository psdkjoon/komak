import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class MemoryQuestion extends StudyQuestion {
  const MemoryQuestion({required this.pairs});

  final List<Flashcard> pairs;

  @override
  QuestionType get type => QuestionType.memory;
}
