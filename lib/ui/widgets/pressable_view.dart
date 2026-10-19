import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/theme/app_motion.dart';

class PressableView extends StatefulWidget {
  const PressableView({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.playSound = true,
    this.hoverScale = 1.02,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final bool playSound;
  final double hoverScale;
  final String? semanticLabel;

  @override
  State<PressableView> createState() => _PressableViewState();
}

class _PressableViewState extends State<PressableView> {
  static const double _pressedScale = 0.97;
  static const double _liftOffset = -0.015;

  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _activate() {
    if (widget.playSound) unawaited(SoundService.play(AppSound.tap));
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final raised = _hovered || _focused;
    final scale = _pressed ? _pressedScale : (raised ? widget.hoverScale : 1.0);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (bool value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          onLongPress: widget.onLongPress,
          onLongPressStart: widget.onLongPressStart,
          onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
          onLongPressEnd: widget.onLongPressEnd,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: AppMotion.resolve(context, AppMotion.quick),
            curve: AppMotion.standardCurve,
            child: AnimatedSlide(
              offset:
                  raised && !_pressed ? const Offset(0, _liftOffset) : Offset.zero,
              duration: AppMotion.resolve(context, AppMotion.quick),
              curve: AppMotion.standardCurve,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
