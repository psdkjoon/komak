import 'package:flutter/material.dart';

class FeedbackEvent {
  const FeedbackEvent({
    required this.id,
    required this.correct,
    required this.big,
    required this.message,
  });

  final int id;
  final bool correct;
  final bool big;
  final String message;
}

class PracticeFeedbackController extends ChangeNotifier {
  FeedbackEvent? event;
  int combo = 0;
  int wrongCount = 0;
  int _nextId = 0;

  static const _wrongMessages = ['Not quite', 'Oops!', 'Missed it'];

  void emit({required bool correct, required bool big}) {
    _nextId += 1;
    combo = correct ? combo + 1 : 0;
    if (!correct) wrongCount += 1;
    final String message;
    if (correct) {
      if (combo >= 5) {
        message = 'Unstoppable!';
      } else if (combo >= 3) {
        message = '$combo in a row!';
      } else if (combo == 2) {
        message = 'Nice!';
      } else {
        message = 'Correct!';
      }
    } else {
      message = _wrongMessages[_nextId % _wrongMessages.length];
    }
    event = FeedbackEvent(
      id: _nextId,
      correct: correct,
      big: big,
      message: message,
    );
    notifyListeners();
  }
}
