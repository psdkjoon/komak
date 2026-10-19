import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';

class MasteryRingView extends StatelessWidget {
  const MasteryRingView({
    super.key,
    required this.value,
    required this.color,
    this.size = 40,
  });

  final double value;
  final Color color;
  final double size;

  static const double _strokeWidth = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: AppMotion.resolve(context, Durations.long4),
      curve: AppMotion.emphasizedCurve,
      builder: (context, animated, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: animated,
                strokeWidth: _strokeWidth,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${(animated * 100).round()}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
