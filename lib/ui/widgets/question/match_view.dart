import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/practice_feedback.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/option_button.dart';

class MatchView extends StatefulWidget {
  const MatchView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final MatchQuestion question;
  final ResolveCallback onResolved;

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  late final List<int> _rightOrder = List<int>.generate(
    widget.question.right.length,
    (int i) => i,
  )..shuffle(Random());
  final Set<int> _done = <int>{};
  final Set<String> _missed = <String>{};
  int? _left;
  int? _wrongLeft;
  int? _wrongRight;
  bool _resolved = false;

  MatchQuestion get _q => widget.question;

  void _pickLeft(int index) {
    if (_resolved || _done.contains(index)) return;
    setState(() => _left = index);
  }

  void _pickRight(int slot) {
    final left = _left;
    if (_resolved || left == null) return;
    final rightIndex = _rightOrder[slot];
    if (_done.contains(rightIndex)) return;
    if (rightIndex == left) {
      PracticeFeedback.report(context, true, big: false);
      setState(() {
        _done.add(left);
        _left = null;
      });
      if (_done.length == _q.left.length) {
        _resolved = true;
        widget.onResolved(_missed);
      }
      return;
    }
    PracticeFeedback.report(context, false, big: false);
    _missed.add(_q.cardIds[left]);
    setState(() {
      _wrongLeft = left;
      _wrongRight = slot;
    });
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _wrongLeft = null;
            _wrongRight = null;
          });
        }
      }),
    );
  }

  OptionState _leftState(int i) {
    if (_done.contains(i)) return OptionState.correct;
    if (_wrongLeft == i) return OptionState.wrong;
    if (_left == i) return OptionState.selected;
    return OptionState.neutral;
  }

  OptionState _rightState(int slot) {
    if (_done.contains(_rightOrder[slot])) return OptionState.correct;
    if (_wrongRight == slot) return OptionState.wrong;
    return OptionState.neutral;
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
        spacing: AppSpacing.md,
        children: [
          Text(
            _q.instruction ?? 'Tap one on the left, then its match on the right',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < _q.left.length; i++)
                      OptionButton(
                        label: _q.left[i],
                        state: _leftState(i),
                        onTap: () => _pickLeft(i),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    for (var s = 0; s < _rightOrder.length; s++)
                      OptionButton(
                        label: _q.right[_rightOrder[s]],
                        state: _rightState(s),
                        onTap: () => _pickRight(s),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
