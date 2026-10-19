import 'dart:math';

import 'package:komak/core/text_normalizer.dart';

int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (int i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = min(
        min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    previous = current;
  }
  return previous[b.length];
}

bool answersClose(String input, String expected) {
  final typed = normalizeAnswer(input);
  if (typed.isEmpty) return false;
  for (final option in answerAlternatives(expected)) {
    final target = normalizeAnswer(option);
    if (target.length < 5) continue;
    final allowed = target.length >= 9 ? 2 : 1;
    if (editDistance(typed, target) <= allowed) return true;
  }
  return false;
}
