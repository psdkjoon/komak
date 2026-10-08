import 'package:komak/core/models/question_type.dart';

abstract class StudyQuestion {
  const StudyQuestion();

  QuestionType get type;
}
