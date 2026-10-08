import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class ScrambleQuestion extends StudyQuestion {
  const ScrambleQuestion({
    required this.card,
    required this.target,
    required this.letters,
  });

  final Flashcard card;
  final String target;
  final List<String> letters;

  @override
  QuestionType get type => QuestionType.scramble;
}
