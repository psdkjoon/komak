import 'package:flutter/material.dart' hide Icon, Text;

class LineChartView extends StatelessWidget {
  const LineChartView({super.key, required this.values, required this.color});

  final List<double?> values;
  final Color color;

  static const double _height = 120;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(
            values: values,
            color: color,
            gridColor: scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double?> values;
  final Color color;
  final Color gridColor;

  static const double _dot = 3;
  static const double _stroke = 2.5;
  static const double _inset = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = _inset + (size.height - _inset * 2) * (1 - fraction);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;

    final step = size.width / (values.length - 1);
    Offset point(int i, double value) => Offset(
          step * i,
          _inset + (size.height - _inset * 2) * (1 - value.clamp(0, 1)),
        );

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    final dot = Paint()..color = color;

    var run = <int>[];
    void flush() {
      if (run.isEmpty) return;
      final path = Path()..moveTo(
          point(run.first, values[run.first]!).dx,
          point(run.first, values[run.first]!).dy,
        );
      for (final i in run.skip(1)) {
        final p = point(i, values[i]!);
        path.lineTo(p.dx, p.dy);
      }
      if (run.length > 1) {
        final area = Path.from(path)
          ..lineTo(point(run.last, 0).dx, size.height)
          ..lineTo(point(run.first, 0).dx, size.height)
          ..close();
        canvas
          ..drawPath(area, fill)
          ..drawPath(path, stroke);
      }
      for (final i in run) {
        canvas.drawCircle(point(i, values[i]!), _dot, dot);
      }
      run = <int>[];
    }

    for (var i = 0; i < values.length; i++) {
      if (values[i] == null) {
        flush();
      } else {
        run.add(i);
      }
    }
    flush();
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}
