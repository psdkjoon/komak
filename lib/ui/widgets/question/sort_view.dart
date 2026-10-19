import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/practice_feedback.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/option_button.dart';
import 'package:komak/ui/widgets/question/prompt_card.dart';

class SortView extends StatefulWidget {
  const SortView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final SortQuestion question;
  final ResolveCallback onResolved;

  @override
  State<SortView> createState() => _SortViewState();
}

class _SortViewState extends State<SortView> {
  final Set<String> _missed = <String>{};
  int _index = 0;
  int? _picked;
  bool _locked = false;

  SortQuestion get _q => widget.question;

  void _pick(int bucket) {
    if (_locked) return;
    final right = bucket == _q.itemBucket[_index];
    PracticeFeedback.report(context, right, big: false);
    if (!right) _missed.add(_q.cardIds[_index]);
    setState(() {
      _picked = bucket;
      _locked = true;
    });
    unawaited(
      Future<void>.delayed(Duration(milliseconds: right ? 450 : 1100), () {
        if (!mounted) return;
        if (_index + 1 >= _q.items.length) {
          widget.onResolved(_missed);
          return;
        }
        setState(() {
          _index += 1;
          _picked = null;
          _locked = false;
        });
      }),
    );
  }

  OptionState _stateFor(int bucket) {
    if (_picked == null) return OptionState.neutral;
    if (bucket == _q.itemBucket[_index]) return OptionState.correct;
    if (bucket == _picked) return OptionState.wrong;
    return OptionState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xl,
        children: [
          Column(
            spacing: AppSpacing.sm,
            children: [
              Text(
                _q.instruction ?? 'Sort each item into its group',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text.verbatim(
                '${_index + 1} / ${_q.items.length}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          PromptCard(text: _q.items[_index]),
          Column(
            children: [
              for (var b = 0; b < _q.buckets.length; b++)
                OptionButton(
                  label: _q.buckets[b],
                  state: _stateFor(b),
                  onTap: _locked ? null : () => _pick(b),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
