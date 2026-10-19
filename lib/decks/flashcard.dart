import 'package:komak/core/id_generator.dart';

enum CardStage { fresh, learning, young, mature }

class Flashcard {
  Flashcard({
    String? id,
    required this.front,
    required this.back,
    this.reading,
    this.example,
    this.note,
    this.orderIndex,
    this.groupId,
    this.imagePath,
    this.timesShown = 0,
    this.timesCorrect = 0,
    this.lastShownAt,
    this.ease = defaultEase,
    this.intervalDays = 0,
    this.reps = 0,
    this.lapses = 0,
    this.dueAt,
  }) : id = id ?? IdGenerator.next();

  static const double defaultEase = 2.5;
  static const int youngLimitDays = 3;
  static const int matureLimitDays = 21;

  final String id;
  final String front;
  final String back;
  final String? reading;
  final String? example;
  final String? note;
  final int? orderIndex;
  final String? groupId;
  final String? imagePath;

  int timesShown;
  int timesCorrect;
  DateTime? lastShownAt;
  double ease;
  int intervalDays;
  int reps;
  int lapses;
  DateTime? dueAt;

  double get accuracy => timesShown == 0 ? 0.5 : timesCorrect / timesShown;

  bool get isNew => reps == 0 && dueAt == null;

  bool isDue([DateTime? now]) {
    final due = dueAt;
    if (isNew || due == null) return false;
    return !due.isAfter(now ?? DateTime.now());
  }

  CardStage get stage {
    if (isNew) return CardStage.fresh;
    if (intervalDays < youngLimitDays) return CardStage.learning;
    if (intervalDays < matureLimitDays) return CardStage.young;
    return CardStage.mature;
  }

  bool get hasExtras =>
      (reading ?? '').isNotEmpty ||
      (example ?? '').isNotEmpty ||
      (note ?? '').isNotEmpty;

  bool matches(String needle) {
    final q = needle.trim().toLowerCase();
    if (q.isEmpty) return true;
    return front.toLowerCase().contains(q) ||
        back.toLowerCase().contains(q) ||
        (reading ?? '').toLowerCase().contains(q) ||
        (example ?? '').toLowerCase().contains(q) ||
        (note ?? '').toLowerCase().contains(q) ||
        (groupId ?? '').toLowerCase().contains(q);
  }

  void registerAttempt({required bool wasCorrect}) {
    timesShown += 1;
    if (wasCorrect) {
      timesCorrect += 1;
    }
    lastShownAt = DateTime.now();
  }

  Flashcard copyWith({
    String? front,
    String? back,
    String? reading,
    String? example,
    String? note,
    int? orderIndex,
    String? groupId,
    String? imagePath,
    bool clearReading = false,
    bool clearExample = false,
    bool clearNote = false,
    bool clearOrder = false,
    bool clearGroup = false,
  }) {
    return Flashcard(
      id: id,
      front: front ?? this.front,
      back: back ?? this.back,
      reading: clearReading ? null : reading ?? this.reading,
      example: clearExample ? null : example ?? this.example,
      note: clearNote ? null : note ?? this.note,
      orderIndex: clearOrder ? null : orderIndex ?? this.orderIndex,
      groupId: clearGroup ? null : groupId ?? this.groupId,
      imagePath: imagePath ?? this.imagePath,
      timesShown: timesShown,
      timesCorrect: timesCorrect,
      lastShownAt: lastShownAt,
      ease: ease,
      intervalDays: intervalDays,
      reps: reps,
      lapses: lapses,
      dueAt: dueAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'front': front,
      'back': back,
      'reading': reading,
      'example': example,
      'note': note,
      'orderIndex': orderIndex,
      'groupId': groupId,
      'imagePath': imagePath,
      'timesShown': timesShown,
      'timesCorrect': timesCorrect,
      'lastShownAt': lastShownAt?.toIso8601String(),
      'ease': ease,
      'intervalDays': intervalDays,
      'reps': reps,
      'lapses': lapses,
      'dueAt': dueAt?.toIso8601String(),
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String?,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      reading: json['reading'] as String?,
      example: json['example'] as String?,
      note: json['note'] as String?,
      orderIndex: json['orderIndex'] as int?,
      groupId: json['groupId'] as String?,
      imagePath: json['imagePath'] as String?,
      timesShown: json['timesShown'] as int? ?? 0,
      timesCorrect: json['timesCorrect'] as int? ?? 0,
      lastShownAt: json['lastShownAt'] == null
          ? null
          : DateTime.tryParse(json['lastShownAt'] as String),
      ease: (json['ease'] as num?)?.toDouble() ?? defaultEase,
      intervalDays: json['intervalDays'] as int? ?? 0,
      reps: json['reps'] as int? ?? 0,
      lapses: json['lapses'] as int? ?? 0,
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.tryParse(json['dueAt'] as String),
    );
  }
}
