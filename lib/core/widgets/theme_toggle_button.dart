import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/core/models/app_settings.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_theme.dart';
import 'package:komak/core/theme/theme_variant_scope.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/pressable_scale.dart';

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
    final bool isDark = ThemeVariantScope.of(context) == AppThemeVariant.mocha;
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
    final controller = AppScope.read(context);
    controller.sound.play(AppSound.whoosh);
    controller.updateSettings(
      (AppSettings s) => s.copyWith(
        followSystemTheme: false,
        themeVariant: isDark ? AppThemeVariant.latte : AppThemeVariant.mocha,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeVariantScope.of(context) == AppThemeVariant.mocha;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Tooltip(
      message: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      child: PressableScale(
        playSound: false,
        semanticLabel:
            isDark ? 'Switch to light theme' : 'Switch to dark theme',
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
            builder: (BuildContext context, Widget? child) {
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
    final Offset center = size.center(Offset.zero);
    final double unit = size.width * 0.2;
    final double t = progress.clamp(0.0, 1.0);
    final Color bodyColor = Color.lerp(sunColor, moonColor, t)!;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-t * math.pi);

    final double bodyRadius = unit * (1 + 0.32 * t);
    final Path body = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: bodyRadius));
    final Offset cutCenter = Offset.lerp(
      Offset(-unit * 3.4, unit * 3.4),
      Offset(-unit * 0.62, unit * 0.5),
      t,
    )!;
    final Path cut = Path()
      ..addOval(Rect.fromCircle(center: cutCenter, radius: bodyRadius * 0.82));
    final Path shape = Path.combine(PathOperation.difference, body, cut);
    canvas.drawPath(shape, Paint()..color = bodyColor);

    final double rayOpacity = 1 - t;
    if (rayOpacity > 0.01) {
      final Paint ray = Paint()
        ..color = sunColor.withValues(alpha: rayOpacity)
        ..strokeWidth = size.width * 0.045
        ..strokeCap = StrokeCap.round;
      final double inner = bodyRadius + unit * 0.5;
      final double outer = inner + unit * 0.55 * rayOpacity;
      for (int i = 0; i < 8; i++) {
        final double angle = i * math.pi / 4;
        canvas.drawLine(
          Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          ray,
        );
      }
    }
    canvas.restore();

    if (t > 0.05) {
      final Paint star = Paint()..color = starColor.withValues(alpha: 0.85 * t);
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
