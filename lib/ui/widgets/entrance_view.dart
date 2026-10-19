import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komak/theme/app_motion.dart';

class EntranceView extends StatefulWidget {
  const EntranceView({
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
  State<EntranceView> createState() => _EntranceViewState();
}

class _EntranceViewState extends State<EntranceView>
    with SingleTickerProviderStateMixin {
  static const int _stepMilliseconds = 55;
  static const int _maxSteps = 10;

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
    final wait = widget.delay +
        Duration(milliseconds: _stepMilliseconds * widget.index.clamp(0, _maxSteps));
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
