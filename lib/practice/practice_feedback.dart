import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/platform/haptics_service.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/practice/practice_feedback_controller.dart';
import 'package:komak/theme/app_motion.dart';

class PracticeFeedbackScope extends InheritedWidget {
  const PracticeFeedbackScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final PracticeFeedbackController controller;

  static PracticeFeedbackController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<PracticeFeedbackScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(PracticeFeedbackScope oldWidget) =>
      controller != oldWidget.controller;
}

abstract class PracticeFeedback {
  static void report(BuildContext context, bool correct, {bool big = true}) {
    final feedback = PracticeFeedbackScope.maybeOf(context);
    feedback?.emit(correct: correct, big: big);
    final combo = feedback?.combo ?? 1;
    unawaited(
      SoundService.play(
        correct ? AppSound.correct : AppSound.wrong,
        variant: correct ? math.min(combo - 1, 3) : -1,
      ),
    );
    if (!correct) unawaited(HapticsService.wrong());
  }

  static Duration answerDelay(
    BuildContext context,
    bool correct,
    Duration whenCorrect,
  ) {
    if (!correct) return const Duration(milliseconds: 2800);
    return AppMotion.resolve(context, whenCorrect);
  }
}
