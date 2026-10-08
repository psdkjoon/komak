import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_colors_extension.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/celebration_burst.dart';
import 'package:komak/core/widgets/shake_widget.dart';

class FeedbackEvent {
  const FeedbackEvent(
      {required this.id,
      required this.correct,
      required this.big,
      required this.message,});

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

  static const List<String> _wrongMessages = <String>[
    'Not quite',
    'Oops!',
    'Missed it',
  ];

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
        id: _nextId, correct: correct, big: big, message: message,);
    notifyListeners();
  }
}

class PracticeFeedbackScope extends InheritedWidget {
  const PracticeFeedbackScope(
      {super.key, required this.controller, required super.child,});

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
    final app = AppScope.read(context);
    final PracticeFeedbackController? feedback =
        PracticeFeedbackScope.maybeOf(context);
    feedback?.emit(correct: correct, big: big);
    final int combo = feedback?.combo ?? 1;
    unawaited(app.sound.play(correct ? AppSound.correct : AppSound.wrong,
        variant: correct ? math.min(combo - 1, 3) : -1,),);
    if (!correct) unawaited(app.haptics.wrong());
  }

  static Duration answerDelay(
      BuildContext context, bool correct, Duration whenCorrect,) {
    if (!correct) return const Duration(milliseconds: 2800);
    return AppMotion.resolve(context, whenCorrect);
  }
}

class PracticeFeedbackLayer extends StatefulWidget {
  const PracticeFeedbackLayer(
      {super.key, required this.controller, required this.child,});

  final PracticeFeedbackController controller;
  final Widget child;

  @override
  State<PracticeFeedbackLayer> createState() => _PracticeFeedbackLayerState();
}

class _PracticeFeedbackLayerState extends State<PracticeFeedbackLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  FeedbackEvent? _shown;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100),);
    widget.controller.addListener(_onEvent);
  }

  void _onEvent() {
    if (!mounted) return;
    setState(() => _shown = widget.controller.event);
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onEvent);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FeedbackEvent? event = _shown;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ShakeWidget(
            trigger: widget.controller.wrongCount,
            distance: 12,
            child: widget.child,),
        if (event != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (BuildContext context, Widget? child) =>
                  _overlay(context, event, _anim.value),
            ),
          ),
      ],
    );
  }

  Widget _overlay(BuildContext context, FeedbackEvent event, double t) {
    if (t >= 1) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final bool reduced = AppMotion.isReduced(context);
    final Color color =
        event.correct ? context.appColors.success : theme.colorScheme.error;
    final double pulse = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
    final int combo = widget.controller.combo;
    final bool hot = event.correct && combo >= 3;
    final Color fire = context.appColors.streak;
    final double glow =
        (event.correct ? (hot ? 0.34 : 0.22) : 0.38) * pulse.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.05,
              colors: <Color>[
                (hot ? fire : color).withValues(alpha: 0),
                (hot ? fire : color).withValues(alpha: glow),
              ],
              stops: const <double>[0.55, 1],
            ),
          ),
        ),
        if (hot && !reduced)
          Positioned.fill(
            child: CustomPaint(
                painter: _ComboRingPainter(
                    t: t,
                    color: fire,
                    strength: math.min(1.0, (combo - 2) / 4),),),
          ),
        if (event.correct && event.big && !reduced)
          Center(
            child: KeyedSubtree(
              key: ValueKey<int>(event.id),
              child: CelebrationBurst(
                size: combo >= 5 ? 460 : (combo >= 3 ? 400 : 340),
                colors: <Color>[
                  context.appColors.success,
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                  context.appColors.warning,
                ],
              ),
            ),
          ),
        if (event.big)
          Align(
              alignment: const Alignment(0, -0.15),
              child: _badge(context, event, color, t, reduced),),
      ],
    );
  }

  Widget _badge(BuildContext context, FeedbackEvent event, Color color,
      double t, bool reduced,) {
    final ThemeData theme = Theme.of(context);
    final double opacity = t < 0.7 ? 1 : 1 - (t - 0.7) / 0.3;
    final double pop = reduced
        ? 1
        : (event.correct
            ? Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0))
            : Curves.easeOutBack.transform((t / 0.25).clamp(0.0, 1.0)));
    final double wobble =
        event.correct || reduced ? 0 : math.sin(t * 22) * 0.14 * (1 - t);
    final double drop = event.correct || reduced
        ? 0
        : (1 - Curves.easeOut.transform(t.clamp(0.0, 1.0))) * -18;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, drop),
        child: Transform.rotate(
          angle: wobble,
          child: Transform.scale(
            scale: pop,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md,),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: color, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: color.withValues(alpha: 0.35), blurRadius: 28,),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    event.correct
                        ? (widget.controller.combo >= 3
                            ? Icons.local_fire_department_rounded
                            : Icons.celebration_rounded)
                        : Icons.sentiment_dissatisfied_rounded,
                    color: event.correct && widget.controller.combo >= 3
                        ? context.appColors.streak
                        : color,
                    size: 34,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(event.message,
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: color, fontWeight: FontWeight.w700,),),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComboRingPainter extends CustomPainter {
  _ComboRingPainter(
      {required this.t, required this.color, required this.strength,});

  final double t;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.42);
    final double maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    for (int i = 0; i < 2 + (strength * 2).round(); i++) {
      final double local = ((t * 1.4) - i * 0.12).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final double radius = maxRadius * Curves.easeOut.transform(local);
      final double alpha = (1 - local) * 0.55;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * (1 - local) + 1
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ComboRingPainter oldDelegate) => oldDelegate.t != t;
}
