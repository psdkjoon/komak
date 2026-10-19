import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:komak/theme/app_motion.dart';

class PopView extends StatefulWidget {
  const PopView({super.key, required this.child, required this.trigger});

  final Widget child;
  final int trigger;

  @override
  State<PopView> createState() => _PopViewState();
}

class _PopViewState extends State<PopView>
    with SingleTickerProviderStateMixin {
  static const double _amplitude = 0.06;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppMotion.emphasized);
  }

  @override
  void didUpdateWidget(PopView oldWidget) {
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
        final scale = 1 + _amplitude * math.sin(_controller.value * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}
