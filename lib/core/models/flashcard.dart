import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

class Flashcard {
  Flashcard({
    String? id,
    required this.front,
    required this.back,
    this.orderIndex,
    this.groupId,
    this.imagePath,
    this.timesShown = 0,
    this.timesCorrect = 0,
    this.lastShownAt,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String front;
  final String back;
  final int? orderIndex;
  final String? groupId;
  final String? imagePath;

  int timesShown;
  int timesCorrect;
  DateTime? lastShownAt;

  double get accuracy => timesShown == 0 ? 0.5 : timesCorrect / timesShown;

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
    int? orderIndex,
    String? groupId,
    String? imagePath,
  }) {
    return Flashcard(
      id: id,
      front: front ?? this.front,
      back: back ?? this.back,
      orderIndex: orderIndex ?? this.orderIndex,
      groupId: groupId ?? this.groupId,
      imagePath: imagePath ?? this.imagePath,
      timesShown: timesShown,
      timesCorrect: timesCorrect,
      lastShownAt: lastShownAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'front': front,
      'back': back,
      'orderIndex': orderIndex,
      'groupId': groupId,
      'imagePath': imagePath,
      'timesShown': timesShown,
      'timesCorrect': timesCorrect,
      'lastShownAt': lastShownAt?.toIso8601String(),
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String?,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      orderIndex: json['orderIndex'] as int?,
      groupId: json['groupId'] as String?,
      imagePath: json['imagePath'] as String?,
      timesShown: json['timesShown'] as int? ?? 0,
      timesCorrect: json['timesCorrect'] as int? ?? 0,
      lastShownAt: json['lastShownAt'] == null
          ? null
          : DateTime.tryParse(json['lastShownAt'] as String),
    );
  }
}
