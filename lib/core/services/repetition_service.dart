import 'dart:math';

import 'package:komak/core/models/flashcard.dart';

class RepetitionService {
  final Random _random = Random();

  List<Flashcard> pickSessionCards(List<Flashcard> pool, int count) {
    if (pool.isEmpty) return <Flashcard>[];
    final int targetCount = min(count, pool.length);
    final List<Flashcard> remaining = List<Flashcard>.from(pool);
    final List<Flashcard> chosen = <Flashcard>[];

    while (chosen.length < targetCount && remaining.isNotEmpty) {
      final List<double> weights = remaining.map(_scoreOf).toList();
      final double totalWeight =
          weights.fold(0, (double sum, double w) => sum + w);
      double roll = _random.nextDouble() * totalWeight;
      int pickedIndex = remaining.length - 1;
      for (int i = 0; i < weights.length; i++) {
        roll -= weights[i];
        if (roll <= 0) {
          pickedIndex = i;
          break;
        }
      }
      chosen.add(remaining.removeAt(pickedIndex));
    }

    return chosen;
  }

  double _scoreOf(Flashcard card) {
    const double baseWeight = 1.0;
    final double recencyWeight = _recencyWeight(card.lastShownAt);
    final double accuracyWeight = 1.6 - card.accuracy;
    return baseWeight * recencyWeight * accuracyWeight;
  }

  double _recencyWeight(DateTime? lastShownAt) {
    if (lastShownAt == null) return 2.2;
    final int minutesSince = DateTime.now().difference(lastShownAt).inMinutes;
    if (minutesSince < 2) return 0.25;
    if (minutesSince < 30) return 0.6;
    if (minutesSince < 60 * 6) return 1.0;
    if (minutesSince < 60 * 24) return 1.4;
    return 1.9;
  }
}
