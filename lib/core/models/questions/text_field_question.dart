import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';
import 'package:komak/core/utils/text_normalizer.dart';

class TextFieldQuestion extends StudyQuestion {
  const TextFieldQuestion({required this.card});

  final Flashcard card;

  @override
  QuestionType get type => QuestionType.textField;

  bool isAnswerCorrect(String input) => answersMatch(input, card.back);
}
