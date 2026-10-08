import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/text_field_question.dart';

class HintTypingQuestion extends TextFieldQuestion {
  const HintTypingQuestion({required super.card, required this.hint});

  final String hint;

  @override
  QuestionType get type => QuestionType.hintTyping;
}
