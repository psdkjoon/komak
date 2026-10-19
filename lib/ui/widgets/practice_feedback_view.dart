import 'dart:math' as math;

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/practice_feedback_controller.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/widgets/celebration_view.dart';
import 'package:komak/ui/widgets/shake_view.dart';

class PracticeFeedbackView extends StatefulWidget {
  const PracticeFeedbackView({
    super.key,
    required this.controller,
    required this.child,
  });

  final PracticeFeedbackController controller;
  final Widget child;

  @override
  State<PracticeFeedbackView> createState() => _PracticeFeedbackViewState();
}

class _PracticeFeedbackViewState extends State<PracticeFeedbackView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  FeedbackEvent? _shown;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
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
    final event = _shown;
    return Stack(
      fit: StackFit.expand,
      children: [
        ShakeView(
          trigger: widget.controller.wrongCount,
          distance: 12,
          child: widget.child,
        ),
        if (event != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) => _overlay(context, event, _anim.value),
            ),
          ),
      ],
    );
  }

  Widget _overlay(BuildContext context, FeedbackEvent event, double t) {
    if (t >= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    final reduced = AppMotion.isReduced(context);
    final color = event.correct ? status.success : theme.colorScheme.error;
    final double pulse = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
    final combo = widget.controller.combo;
    final hot = event.correct && combo >= 3;
    final fire = status.streak;
    final double glow =
        (event.correct ? (hot ? 0.34 : 0.22) : 0.38) * pulse.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.05,
              colors: [
                (hot ? fire : color).withValues(alpha: 0),
                (hot ? fire : color).withValues(alpha: glow),
              ],
              stops: const [0.55, 1],
            ),
          ),
        ),
        if (hot && !reduced)
          Positioned.fill(
            child: CustomPaint(
              painter: _ComboRingPainter(
                t: t,
                color: fire,
                strength: math.min(1.0, (combo - 2) / 4),
              ),
            ),
          ),
        if (event.correct && event.big && !reduced)
          Center(
            child: KeyedSubtree(
              key: ValueKey(event.id),
              child: CelebrationView(
                size: combo >= 5 ? 460 : (combo >= 3 ? 400 : 340),
                colors: [
                  status.success,
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                  status.warning,
                ],
              ),
            ),
          ),
        if (event.big)
          Align(
            alignment: const Alignment(0, -0.15),
            child: _badge(context, event, color, t, reduced),
          ),
      ],
    );
  }

  Widget _badge(
    BuildContext context,
    FeedbackEvent event,
    Color color,
    double t,
    bool reduced,
  ) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
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
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    event.correct
                        ? (widget.controller.combo >= 3
                            ? Icons.local_fire_department_rounded
                            : Icons.celebration_rounded)
                        : Icons.sentiment_dissatisfied_rounded,
                    color: event.correct && widget.controller.combo >= 3
                        ? status.streak
                        : color,
                    size: 34,
                  ),
                  Text(
                    event.message,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
  _ComboRingPainter({
    required this.t,
    required this.color,
    required this.strength,
  });

  final double t;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    for (var i = 0; i < 2 + (strength * 2).round(); i++) {
      final local = ((t * 1.4) - i * 0.12).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final radius = maxRadius * Curves.easeOut.transform(local);
      final alpha = (1 - local) * 0.55;
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
