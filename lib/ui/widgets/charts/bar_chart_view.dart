import 'package:flutter/material.dart';
import 'package:komak/theme/app_spacing.dart';

class BarChartView extends StatelessWidget {
  const BarChartView({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.overlay,
  });

  final List<double> values;
  final List<double>? overlay;
  final List<String> labels;
  final Color color;

  static const double _height = 120;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        spacing: AppSpacing.xxs,
        children: [
          SizedBox(
            height: _height,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarsPainter(
                values: values,
                overlay: overlay,
                color: color,
                gridColor: scheme.outlineVariant,
              ),
            ),
          ),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: labelStyle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.overlay,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final List<double>? overlay;
  final Color color;
  final Color gridColor;

  static const double _gapFraction = 0.3;
  static const double _radius = 4;
  static const double _minBar = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = size.height - size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;

    var peak = 1.0;
    for (final value in values) {
      if (value > peak) peak = value;
    }
    final slot = size.width / values.length;
    final barWidth = slot * (1 - _gapFraction);
    final track = Paint()..color = color.withValues(alpha: 0.3);
    final solid = Paint()..color = color;

    for (var i = 0; i < values.length; i++) {
      final left = slot * i + (slot - barWidth) / 2;
      final total = values[i];
      if (total <= 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, size.height - _minBar, barWidth, _minBar),
            const Radius.circular(_radius),
          ),
          track,
        );
        continue;
      }
      final totalHeight = size.height * total / peak;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - totalHeight, barWidth, totalHeight),
          const Radius.circular(_radius),
        ),
        overlay == null ? solid : track,
      );
      final inner = overlay;
      if (inner != null && inner[i] > 0) {
        final innerHeight = size.height * inner[i] / peak;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              left,
              size.height - innerHeight,
              barWidth,
              innerHeight,
            ),
            const Radius.circular(_radius),
          ),
          solid,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.overlay != overlay ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}
