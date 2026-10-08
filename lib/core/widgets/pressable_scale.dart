import 'package:flutter/material.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/widgets/app_scope.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.playSound = true,
    this.hoverScale = 1.02,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool playSound;
  final double hoverScale;
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _activate() {
    if (widget.playSound) AppScope.read(context).sound.play(AppSound.tap);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool raised = _hovered || _focused;
    final double scale = _pressed ? 0.97 : (raised ? widget.hoverScale : 1.0);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
        onShowFocusHighlight: (bool value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          onLongPress: widget.onLongPress,
          onTapDown: (TapDownDetails _) => setState(() => _pressed = true),
          onTapUp: (TapUpDetails _) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: AppMotion.resolve(context, AppMotion.quick),
            curve: AppMotion.standardCurve,
            child: AnimatedSlide(
              offset:
                  raised && !_pressed ? const Offset(0, -0.015) : Offset.zero,
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
