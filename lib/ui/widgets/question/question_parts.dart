import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/prompt_card.dart';

class CountdownBar extends StatefulWidget {
  const CountdownBar({
    required this.seconds,
    required this.onDone,
    super.key,
    this.active = true,
  });

  final int seconds;
  final VoidCallback onDone;
  final bool active;

  @override
  State<CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<CountdownBar> {
  static const double _barHeight = 8;
  static const double _urgentThreshold = 0.3;
  static const Duration _tick = Duration(milliseconds: 100);

  Timer? _timer;
  late final DateTime _start;
  double _remaining = 1;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _timer = Timer.periodic(_tick, (Timer timer) {
      final elapsed = DateTime.now().difference(_start).inMilliseconds;
      final total = widget.seconds * 1000;
      if (!mounted) return;
      if (elapsed >= total) {
        timer.cancel();
        setState(() => _remaining = 0);
        if (!_done && widget.active) {
          _done = true;
          widget.onDone();
        }
        return;
      }
      setState(() => _remaining = 1 - elapsed / total);
    });
  }

  @override
  void didUpdateWidget(CountdownBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: _remaining,
        minHeight: _barHeight,
        color: _remaining < _urgentThreshold ? scheme.error : scheme.tertiary,
        backgroundColor: scheme.surfaceContainerHigh,
      ),
    );
  }
}

class PromptBlock extends StatelessWidget {
  const PromptBlock({
    required this.prompt,
    super.key,
    this.instruction,
    this.detail,
  });

  final String prompt;
  final String? instruction;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        if (instruction != null)
          Text(
            instruction!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        if (prompt.isNotEmpty) PromptCard(text: prompt),
        if (detail != null && detail!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Text.verbatim(
              detail!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class PreviewGate extends StatefulWidget {
  const PreviewGate({
    required this.preview,
    required this.child,
    super.key,
  });

  final Preview? preview;
  final Widget child;

  @override
  State<PreviewGate> createState() => _PreviewGateState();
}

class _PreviewGateState extends State<PreviewGate> {
  late bool _done = widget.preview == null;

  void _finish() {
    if (mounted && !_done) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    return AnimatedSwitcher(
      duration: AppMotion.resolve(context, AppMotion.standard),
      child: _done || preview == null
          ? KeyedSubtree(key: const ValueKey<bool>(true), child: widget.child)
          : _PreviewPanel(
              key: const ValueKey<bool>(false),
              preview: preview,
              onDone: _finish,
            ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.preview,
    required this.onDone,
    super.key,
  });

  final Preview preview;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        CountdownBar(seconds: preview.seconds, onDone: onDone),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  preview.title ?? 'Look carefully',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                for (final line in preview.lines) PromptCard(text: line),
              ],
            ),
          ),
        ),
        FilledButton(onPressed: onDone, child: const Text('I am ready')),
      ],
    );
  }
}
