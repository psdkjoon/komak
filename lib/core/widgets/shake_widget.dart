import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/core/theme/app_motion.dart';

class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    required this.trigger,
    this.distance = 8,
  });

  final Widget child;
  final int trigger;
  final double distance;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppMotion.emphasized);
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
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
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double dx = math.sin(t * math.pi * 6) * widget.distance * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

class PopWidget extends StatefulWidget {
  const PopWidget({super.key, required this.child, required this.trigger});

  final Widget child;
  final int trigger;

  @override
  State<PopWidget> createState() => _PopWidgetState();
}

class _PopWidgetState extends State<PopWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppMotion.emphasized);
  }

  @override
  void didUpdateWidget(PopWidget oldWidget) {
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
      builder: (BuildContext context, Widget? child) {
        final double scale = 1 + 0.06 * math.sin(_controller.value * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}
