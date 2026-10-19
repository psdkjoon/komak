import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/theme/app_motion.dart';

class ShakeView extends StatefulWidget {
  const ShakeView({
    super.key,
    required this.child,
    required this.trigger,
    this.distance = 8,
  });

  final Widget child;
  final int trigger;
  final double distance;

  @override
  State<ShakeView> createState() => _ShakeViewState();
}

class _ShakeViewState extends State<ShakeView>
    with SingleTickerProviderStateMixin {
  static const double _swings = 6;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppMotion.emphasized);
  }

  @override
  void didUpdateWidget(ShakeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && !AppMotion.isReduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * _swings) * widget.distance * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
