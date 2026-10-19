import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/theme/app_motion.dart';

class CelebrationView extends StatefulWidget {
  const CelebrationView({super.key, required this.colors, this.size = 240});

  final List<Color> colors;
  final double size;

  @override
  State<CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<CelebrationView>
    with SingleTickerProviderStateMixin {
  static const int _particleCount = 34;

  late final AnimationController _controller;
  late final List<_Particle> _particles;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Durations.extralong4);
    final random = math.Random(7);
    _particles = List<_Particle>.generate(_particleCount, (i) {
      return _Particle(
        angle: random.nextDouble() * math.pi * 2,
        speed: 0.45 + random.nextDouble() * 0.55,
        radius: 2.5 + random.nextDouble() * 3.5,
        colorIndex: random.nextInt(widget.colors.length),
        spin: random.nextDouble() * 2 - 1,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!AppMotion.isReduced(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BurstPainter(
                progress:
                    Easing.standardDecelerate.transform(_controller.value),
                fade: _controller.value,
                particles: _particles,
                colors: widget.colors,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.colorIndex,
    required this.spin,
  });

  final double angle;
  final double speed;
  final double radius;
  final int colorIndex;
  final double spin;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.progress,
    required this.fade,
    required this.particles,
    required this.colors,
  });

  final double progress;
  final double fade;
  final List<_Particle> particles;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = size.width * 0.5;
    for (final particle in particles) {
      final distance = reach * particle.speed * progress;
      final drift = particle.spin * progress * 0.6;
      final angle = particle.angle + drift;
      final position = center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + progress * progress * 26,
          );
      final opacity = (1 - fade * fade).clamp(0.0, 1.0);
      canvas.drawCircle(
        position,
        particle.radius * (1 - 0.4 * fade),
        Paint()..color = colors[particle.colorIndex].withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.fade != fade;
}
