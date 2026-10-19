import 'dart:math';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/question_parts.dart';

class ArrangeView extends StatefulWidget {
  const ArrangeView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final ArrangeQuestion question;
  final ResolveCallback onResolved;

  @override
  State<ArrangeView> createState() => _ArrangeViewState();
}

class _ArrangeViewState extends State<ArrangeView> {
  late final List<String> _bank = _shuffled();
  final List<int> _chosen = <int>[];
  bool _resolved = false;
  bool _ok = false;

  ArrangeQuestion get _q => widget.question;

  List<String> _shuffled() {
    final all = <String>[..._q.pieces, ..._q.extras];
    final random = Random();
    for (var i = 0; i < 6; i++) {
      all.shuffle(random);
      if (_q.extras.isNotEmpty || all.join(_q.joiner) != _q.reveal) break;
    }
    return all;
  }

  void _toggle(int bankIndex) {
    if (_resolved) return;
    setState(() {
      if (!_chosen.remove(bankIndex)) {
        if (_chosen.length < _q.pieces.length) _chosen.add(bankIndex);
      }
    });
  }

  void _check() {
    if (_resolved || _chosen.length != _q.pieces.length) return;
    final given = <String>[for (final i in _chosen) _bank[i]];
    final ok = given.join(_q.joiner) == _q.reveal;
    final missed = <String>{};
    if (!ok) {
      if (_q.perPiece && _q.cardIds.length == _q.pieces.length) {
        for (var i = 0; i < given.length; i++) {
          if (given[i] != _q.pieces[i]) missed.add(_q.cardIds[i]);
        }
      }
      if (missed.isEmpty) missed.addAll(_q.cardIds);
    }
    setState(() {
      _resolved = true;
      _ok = ok;
    });
    widget.onResolved(missed, note: _q.reveal);
  }

  Widget _chip(
    BuildContext context,
    String text,
    VoidCallback? onTap, {
    Color? background,
    Color? foreground,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: background ?? scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text.verbatim(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground ?? scheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final answerBackground = !_resolved
        ? scheme.surfaceContainer
        : (_ok ? scheme.secondaryContainer : scheme.errorContainer);
    return PreviewGate(
      preview: _q.preview,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            PromptBlock(prompt: _q.prompt, instruction: _q.instruction),
            Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: answerBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final i in _chosen)
                    _chip(
                      context,
                      _bank[i],
                      _resolved ? null : () => _toggle(i),
                      background: scheme.primaryContainer,
                      foreground: scheme.onPrimaryContainer,
                    ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _bank.length; i++)
                  if (!_chosen.contains(i))
                    _chip(context, _bank[i], _resolved ? null : () => _toggle(i)),
              ],
            ),
            if (!_resolved)
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _chosen.isEmpty ? null : () => setState(_chosen.clear),
                      child: const Text('Clear'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _chosen.length == _q.pieces.length ? _check : null,
                      child: const Text('Check'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
