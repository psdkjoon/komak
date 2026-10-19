class DayStats {
  DayStats({this.reviews = 0, this.correct = 0, this.learned = 0});

  int reviews;
  int correct;
  int learned;

  double get accuracy => reviews == 0 ? 0 : correct / reviews;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reviews': reviews,
        'correct': correct,
        'learned': learned,
      };

  factory DayStats.fromJson(Map<String, dynamic> json) {
    return DayStats(
      reviews: json['reviews'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      learned: json['learned'] as int? ?? 0,
    );
  }
}

class StudyStats {
  StudyStats([Map<String, DayStats>? days])
      : _days = days ?? <String, DayStats>{};

  static const int keepDays = 400;

  final Map<String, DayStats> _days;

  static String keyOf(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  DayStats on(DateTime day) => _days[keyOf(day)] ?? DayStats();

  int get totalReviews =>
      _days.values.fold(0, (int sum, DayStats d) => sum + d.reviews);

  int get activeDays =>
      _days.values.where((DayStats d) => d.reviews > 0).length;

  void record({required bool correct, bool learned = false, DateTime? now}) {
    final day = _days.putIfAbsent(keyOf(now ?? DateTime.now()), DayStats.new);
    day.reviews += 1;
    if (correct) day.correct += 1;
    if (learned) day.learned += 1;
    if (_days.length > keepDays + 30) {
      final keys = _days.keys.toList()..sort();
      for (final key in keys.take(_days.length - keepDays)) {
        _days.remove(key);
      }
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        for (final entry in _days.entries) entry.key: entry.value.toJson(),
      };

  factory StudyStats.fromJson(Map<String, dynamic> json) {
    return StudyStats(<String, DayStats>{
      for (final entry in json.entries)
        entry.key: DayStats.fromJson(entry.value as Map<String, dynamic>),
    });
  }
}
