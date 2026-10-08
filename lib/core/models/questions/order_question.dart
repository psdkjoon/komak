import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/study_question.dart';

class OrderQuestion extends StudyQuestion {
  const OrderQuestion({
    required this.title,
    required this.shuffledItems,
    required this.correctOrderIds,
  });

  final String title;
  final List<Flashcard> shuffledItems;
  final List<String> correctOrderIds;

  @override
  QuestionType get type => QuestionType.order;

  bool isOrderCorrect(List<String> attemptedIds) {
    if (attemptedIds.length != correctOrderIds.length) return false;
    for (int i = 0; i < attemptedIds.length; i++) {
      if (attemptedIds[i] != correctOrderIds[i]) return false;
    }
    return true;
  }
}
