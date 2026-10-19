import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/practice_feedback.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/question_parts.dart';

class _Tile {
  const _Tile(this.pair, this.text);

  final int pair;
  final String text;
}

class MemoryView extends StatefulWidget {
  const MemoryView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final MemoryQuestion question;
  final ResolveCallback onResolved;

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView> {
  late final List<_Tile> _tiles = <_Tile>[
    for (var i = 0; i < widget.question.left.length; i++)
      _Tile(i, widget.question.left[i]),
    for (var i = 0; i < widget.question.right.length; i++)
      _Tile(i, widget.question.right[i]),
  ]..shuffle(Random());
  final Set<int> _matched = <int>{};
  final Set<String> _missed = <String>{};
  final List<int> _open = <int>[];
  bool _peeking = true;
  bool _busy = false;

  MemoryQuestion get _q => widget.question;

  void _flip(int index) {
    if (_peeking || _busy) return;
    if (_open.contains(index) || _matched.contains(_tiles[index].pair)) return;
    setState(() => _open.add(index));
    if (_open.length < 2) return;
    final a = _tiles[_open[0]];
    final b = _tiles[_open[1]];
    if (a.pair == b.pair) {
      PracticeFeedback.report(context, true, big: false);
      setState(() {
        _matched.add(a.pair);
        _open.clear();
      });
      if (_matched.length == _q.left.length) widget.onResolved(_missed);
      return;
    }
    PracticeFeedback.report(context, false, big: false);
    _missed
      ..add(_q.cardIds[a.pair])
      ..add(_q.cardIds[b.pair]);
    _busy = true;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _open.clear();
          _busy = false;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        if (_peeking)
          CountdownBar(
            seconds: _q.previewSeconds,
            onDone: () {
              if (mounted) setState(() => _peeking = false);
            },
          ),
        Text(
          _peeking
              ? 'Remember where each one is'
              : 'Find the matching pairs',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.1,
            children: [
              for (var i = 0; i < _tiles.length; i++)
                _tile(context, i),
            ],
          ),
        ),
        if (_peeking)
          FilledButton(
            onPressed: () => setState(() => _peeking = false),
            child: const Text('I am ready'),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final tile = _tiles[index];
    final matched = _matched.contains(tile.pair);
    final faceUp = _peeking || matched || _open.contains(index);
    final background = matched
        ? scheme.secondaryContainer
        : (faceUp ? scheme.surfaceContainerHigh : scheme.primaryContainer);
    return AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.quick),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: () => _flip(index),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: faceUp
                  ? Text.verbatim(
                      tile.text,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : Icon(
                      Icons.help_outline_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
