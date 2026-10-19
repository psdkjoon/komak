import 'dart:math' as math;

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';

class StreakCard extends StatefulWidget {
  const StreakCard({super.key, required this.days, required this.color});

  final int days;
  final Color color;

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard>
    with SingleTickerProviderStateMixin {
  static const double _badgeSize = 44;
  static const double _iconSize = 26;
  static const int _emberCount = 18;

  late final AnimationController _loop;
  late final List<_Ember> _embers;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _loop =
        AnimationController(vsync: this, duration: const Duration(seconds: 9));
    final random = math.Random(11);
    _embers = List<_Ember>.generate(_emberCount, (i) {
      return _Ember(
        x: random.nextDouble(),
        phase: random.nextDouble(),
        speed: 0.6 + random.nextDouble() * 0.9,
        size: 2 + random.nextDouble() * 4,
        sway: random.nextDouble() * 2 * math.pi,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.isReduced(context)) {
      _loop.stop();
      _started = false;
    } else if (!_started) {
      _started = true;
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _StreakPainter(
                        t: _loop.value,
                        color: widget.color,
                        embers: _embers,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: _iconSize,
                      color: widget.color,
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: widget.days.toDouble(),
                    ),
                    duration: AppMotion.resolve(context, Durations.long4),
                    curve: AppMotion.emphasizedCurve,
                    builder: (context, animated, child) {
                      return Text.verbatim(
                        '${animated.round()}',
                        style: theme.textTheme.headlineLarge,
                      );
                    },
                  ),
                  Expanded(
                    child: Text(
                      'day streak',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ember {
  const _Ember({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.sway,
  });

  final double x;
  final double phase;
  final double speed;
  final double size;
  final double sway;
}

class _StreakPainter extends CustomPainter {
  _StreakPainter({required this.t, required this.color, required this.embers});

  final double t;
  final Color color;
  final List<_Ember> embers;

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(t * 2 * math.pi);
    final rect = Offset.zero & size;
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.85 + 0.25 * wave, 1.1),
        radius: 1.3,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final second = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.9 - 0.3 * wave, -1.0),
        radius: 1.0,
        colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, second);

    for (final ember in embers) {
      final progress = (t * ember.speed + ember.phase) % 1.0;
      final x = size.width * ember.x +
          math.sin(progress * 2 * math.pi + ember.sway) * 10;
      final y = size.height * (1.05 - progress * 1.15);
      final fade = math.sin(progress * math.pi);
      canvas.drawCircle(
        Offset(x, y),
        ember.size * (0.6 + 0.4 * fade),
        Paint()..color = color.withValues(alpha: 0.5 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_StreakPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
