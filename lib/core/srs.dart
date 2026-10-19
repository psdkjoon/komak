import 'dart:math' as math;

import 'package:komak/decks/flashcard.dart';

enum Rating { again, hard, good, easy }

abstract class Srs {
  static const double minEase = 1.3;
  static const int maxIntervalDays = 365;
  static const int relearnMinutes = 10;

  static DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int nextInterval(Flashcard card, Rating rating) {
    final current = math.max(card.intervalDays, 1);
    final int days;
    switch (rating) {
      case Rating.again:
        return 0;
      case Rating.hard:
        days = card.isNew ? 1 : (current * 1.2).round();
      case Rating.good:
        if (card.isNew) {
          days = 1;
        } else if (card.intervalDays <= 1) {
          days = 3;
        } else {
          days = (current * card.ease).round();
        }
      case Rating.easy:
        days = card.isNew ? 4 : (current * card.ease * 1.3).round() + 1;
    }
    return days.clamp(1, maxIntervalDays);
  }

  static void review(Flashcard card, Rating rating, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    if (rating == Rating.again) {
      if (!card.isNew) {
        card.lapses += 1;
        card.ease = math.max(minEase, card.ease - 0.2);
        card.intervalDays = 0;
        card.dueAt = moment.add(const Duration(minutes: relearnMinutes));
      }
      return;
    }
    final interval = nextInterval(card, rating);
    switch (rating) {
      case Rating.hard:
        card.ease = math.max(minEase, card.ease - 0.15);
      case Rating.easy:
        card.ease = card.ease + 0.15;
      case Rating.good:
      case Rating.again:
        break;
    }
    card.reps += 1;
    card.intervalDays = interval;
    card.dueAt = _dayStart(moment).add(Duration(days: interval));
  }

  static void practice(Flashcard card, {required bool correct, DateTime? now}) {
    final moment = now ?? DateTime.now();
    if (correct) {
      if (card.isNew || card.isDue(moment)) review(card, Rating.good, now: moment);
    } else if (!card.isNew) {
      review(card, Rating.again, now: moment);
    }
  }
}
