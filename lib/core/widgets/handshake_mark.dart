import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:komak/core/theme/app_motion.dart';

class HandshakeMark extends StatefulWidget {
  const HandshakeMark({super.key, this.size = 32});

  final double size;

  @override
  State<HandshakeMark> createState() => _HandshakeMarkState();
}

class _HandshakeMarkState extends State<HandshakeMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.playful);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.isReduced(context)) return;
    _timer = Timer(Durations.long4, () {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _shake() {
    if (AppMotion.isReduced(context) || _controller.isAnimating) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (PointerEnterEvent _) => _shake(),
      child: GestureDetector(
        onTap: _shake,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = _controller.value;
            final double angle = math.sin(t * math.pi * 6) * 0.3 * (1 - t);
            final double scale = 1 + 0.18 * math.sin(t * math.pi);
            return Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Icon(
            Icons.handshake_rounded,
            size: widget.size,
            color: scheme.tertiary,
          ),
        ),
      ),
    );
  }
}
