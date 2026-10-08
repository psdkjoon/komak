import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class OddOneOutQuestion extends StudyQuestion {
  const OddOneOutQuestion({
    required this.options,
    required this.imposterId,
    required this.sharedGroupLabel,
  });

  final List<Flashcard> options;
  final String imposterId;
  final String sharedGroupLabel;

  @override
  QuestionType get type => QuestionType.oddOneOut;
}
