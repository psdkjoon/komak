import 'package:flutter/material.dart' hide Icon, Text;

class HeatmapView extends StatelessWidget {
  const HeatmapView({
    super.key,
    required this.counts,
    required this.firstDay,
    required this.color,
  });

  final List<int> counts;
  final DateTime firstDay;
  final Color color;

  static const int _rows = 7;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final offset = firstDay.weekday % _rows;
          final columns = ((counts.length + offset) / _rows).ceil();
          final cell = (constraints.maxWidth - _gap * (columns - 1)) / columns;
          return SizedBox(
            width: constraints.maxWidth,
            height: cell * _rows + _gap * (_rows - 1),
            child: CustomPaint(
              painter: _HeatPainter(
                counts: counts,
                offset: offset,
                columns: columns,
                cell: cell,
                color: color,
                empty: scheme.surfaceContainerHigh,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({
    required this.counts,
    required this.offset,
    required this.columns,
    required this.cell,
    required this.color,
    required this.empty,
  });

  final List<int> counts;
  final int offset;
  final int columns;
  final double cell;
  final Color color;
  final Color empty;

  static const double _radius = 3;

  @override
  void paint(Canvas canvas, Size size) {
    var peak = 1;
    for (final count in counts) {
      if (count > peak) peak = count;
    }
    for (var i = 0; i < counts.length; i++) {
      final column = (i + offset) ~/ HeatmapView._rows;
      final row = (i + offset) % HeatmapView._rows;
      final level = counts[i] == 0 ? 0 : (counts[i] * 4 / peak).ceil();
      final paint = Paint()
        ..color = level == 0 ? empty : color.withValues(alpha: 0.2 + level * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            column * (cell + HeatmapView._gap),
            row * (cell + HeatmapView._gap),
            cell,
            cell,
          ),
          const Radius.circular(_radius),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatPainter oldDelegate) =>
      oldDelegate.counts != counts ||
      oldDelegate.color != color ||
      oldDelegate.empty != empty ||
      oldDelegate.cell != cell;
}
