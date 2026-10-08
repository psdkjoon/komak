import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komak/core/theme/app_motion.dart';

class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.12),
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Offset offset;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppMotion.emphasized);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: AppMotion.standardCurve),
    );
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.enterCurve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.isReduced(context)) {
      _controller.value = 1;
      return;
    }
    final Duration wait =
        widget.delay + Duration(milliseconds: 55 * widget.index.clamp(0, 10));
    if (wait == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(wait, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
