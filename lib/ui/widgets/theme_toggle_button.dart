import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/localization/localization.dart' show TrString;
import 'package:komak/theme/app_motion.dart';
import 'package:komak/ui/widgets/pressable_view.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key, this.size = 48});

  final double size;

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Durations.extralong1);
    _progress =
        CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_initialized) {
      _initialized = true;
      _controller.value = isDark ? 1 : 0;
      return;
    }
    if (AppMotion.isReduced(context)) {
      _controller.value = isDark ? 1 : 0;
    } else if (isDark) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(bool isDark) {
    AppScope.read(context).settings.themeMode =
        isDark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: (isDark ? 'Switch to light theme' : 'Switch to dark theme').tr,
      child: PressableView(
        playSound: false,
        semanticLabel:
            (isDark ? 'Switch to light theme' : 'Switch to dark theme').tr,
        onTap: () => _toggle(isDark),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, child) {
              return CustomPaint(
                painter: _SunMoonPainter(
                  progress: _progress.value,
                  sunColor: scheme.tertiary,
                  moonColor: scheme.primary,
                  starColor: scheme.onSurface,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SunMoonPainter extends CustomPainter {
  const _SunMoonPainter({
    required this.progress,
    required this.sunColor,
    required this.moonColor,
    required this.starColor,
  });

  final double progress;
  final Color sunColor;
  final Color moonColor;
  final Color starColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width * 0.2;
    final t = progress.clamp(0.0, 1.0);
    final bodyColor = Color.lerp(sunColor, moonColor, t)!;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-t * math.pi);

    final bodyRadius = unit * (1 + 0.32 * t);
    final body = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: bodyRadius));
    final cutCenter = Offset.lerp(
      Offset(-unit * 3.4, unit * 3.4),
      Offset(-unit * 0.62, unit * 0.5),
      t,
    )!;
    final cut = Path()
      ..addOval(Rect.fromCircle(center: cutCenter, radius: bodyRadius * 0.82));
    final shape = Path.combine(PathOperation.difference, body, cut);
    canvas.drawPath(shape, Paint()..color = bodyColor);

    final rayOpacity = 1 - t;
    if (rayOpacity > 0.01) {
      final ray = Paint()
        ..color = sunColor.withValues(alpha: rayOpacity)
        ..strokeWidth = size.width * 0.045
        ..strokeCap = StrokeCap.round;
      final inner = bodyRadius + unit * 0.5;
      final outer = inner + unit * 0.55 * rayOpacity;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        canvas.drawLine(
          Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          ray,
        );
      }
    }
    canvas.restore();

    if (t > 0.05) {
      final star = Paint()..color = starColor.withValues(alpha: 0.85 * t);
      canvas.drawCircle(
        center + Offset(size.width * 0.24, -size.height * 0.24),
        size.width * 0.032 * t,
        star,
      );
      canvas.drawCircle(
        center + Offset(size.width * 0.3, -size.height * 0.02),
        size.width * 0.022 * t,
        star,
      );
      canvas.drawCircle(
        center + Offset(size.width * 0.1, -size.height * 0.32),
        size.width * 0.018 * t,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(_SunMoonPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sunColor != sunColor ||
        oldDelegate.moonColor != moonColor ||
        oldDelegate.starColor != starColor;
  }
}
