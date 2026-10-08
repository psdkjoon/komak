class StreakData {
  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDay,
    this.totalSessionsCompleted = 0,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDay;
  final int totalSessionsCompleted;

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  StreakData registerStudyToday() {
    final DateTime today = _dayOnly(DateTime.now());
    if (lastStudyDay != null && _dayOnly(lastStudyDay!) == today) {
      return StreakData(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastStudyDay: today,
        totalSessionsCompleted: totalSessionsCompleted + 1,
      );
    }

    final bool isConsecutive = lastStudyDay != null &&
        _dayOnly(lastStudyDay!) == today.subtract(const Duration(days: 1));

    final int nextStreak = isConsecutive ? currentStreak + 1 : 1;

    return StreakData(
      currentStreak: nextStreak,
      longestStreak: nextStreak > longestStreak ? nextStreak : longestStreak,
      lastStudyDay: today,
      totalSessionsCompleted: totalSessionsCompleted + 1,
    );
  }

  bool get isAtRiskToday {
    if (lastStudyDay == null) return false;
    final DateTime today = _dayOnly(DateTime.now());
    return _dayOnly(lastStudyDay!) != today;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDay': lastStudyDay?.toIso8601String(),
      'totalSessionsCompleted': totalSessionsCompleted,
    };
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastStudyDay: json['lastStudyDay'] == null
          ? null
          : DateTime.tryParse(json['lastStudyDay'] as String),
      totalSessionsCompleted: json['totalSessionsCompleted'] as int? ?? 0,
    );
  }
}
