import 'dart:math' as math;

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.showBack,
    required this.onTap,
    required this.accent,
    this.reading,
    this.example,
    this.note,
  });

  final String front;
  final String back;
  final String? reading;
  final String? example;
  final String? note;
  final bool showBack;
  final VoidCallback onTap;
  final Color accent;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Durations.long2,
      value: widget.showBack ? 1 : 0,
    );
    _curve =
        CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedCurve);
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBack != widget.showBack) {
      if (AppMotion.isReduced(context)) {
        _controller.value = widget.showBack ? 1 : 0;
      } else if (widget.showBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.015 : 1,
          duration: AppMotion.quick,
          curve: AppMotion.standardCurve,
          child: AnimatedBuilder(
            animation: _curve,
            builder: (context, child) {
              final angle = _curve.value * math.pi;
              final backVisible = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateY(angle),
                child: backVisible
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _FlipFace(
                          label: 'Answer',
                          text: widget.back,
                          example: widget.example,
                          note: widget.note,
                          accent: widget.accent,
                          isBack: true,
                        ),
                      )
                    : _FlipFace(
                        label: 'Question',
                        text: widget.front,
                        reading: widget.reading,
                        accent: widget.accent,
                        isBack: false,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FlipFace extends StatelessWidget {
  const _FlipFace({
    required this.label,
    required this.text,
    required this.accent,
    required this.isBack,
    this.reading,
    this.example,
    this.note,
  });

  final String label;
  final String text;
  final String? reading;
  final String? example;
  final String? note;
  final Color accent;
  final bool isBack;

  static const double _borderWidth = 1.5;
  static const double _noteIconSize = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: accent.withValues(alpha: isBack ? 0.7 : 0.35),
          width: _borderWidth,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isBack ? 0.26 : 0.12),
            scheme.surfaceContainer,
          ],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: accent),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.md,
                  children: [
                    Text.verbatim(
                      text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    if ((reading ?? '').isNotEmpty)
                      Text.verbatim(
                        reading!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: accent),
                      ),
                    if ((example ?? '').isNotEmpty)
                      Text.verbatim(
                        example!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if ((note ?? '').isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.xxs,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: _noteIconSize,
                            color: accent,
                          ),
                          Flexible(
                            child: Text.verbatim(
                              note!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            isBack ? 'Did you know it?' : 'Tap or press space to flip',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
