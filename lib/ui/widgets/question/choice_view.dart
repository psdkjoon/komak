import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/option_button.dart';
import 'package:komak/ui/widgets/question/question_parts.dart';

class ChoiceView extends StatefulWidget {
  const ChoiceView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final ChoiceQuestion question;
  final ResolveCallback onResolved;

  @override
  State<ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<ChoiceView> {
  final Set<int> _selected = <int>{};
  bool _resolved = false;

  ChoiceQuestion get _q => widget.question;

  void _resolve() {
    if (_resolved) return;
    setState(() => _resolved = true);
    final ok = _selected.length == _q.correct.length &&
        _selected.containsAll(_q.correct);
    widget.onResolved(
      ok ? <String>{} : _q.cardIds.toSet(),
      note: _q.reveal,
    );
  }

  void _tap(int index) {
    if (_resolved) return;
    if (_q.selectAll) {
      setState(() {
        if (!_selected.add(index)) _selected.remove(index);
      });
      return;
    }
    _selected
      ..clear()
      ..add(index);
    _resolve();
  }

  OptionState _stateFor(int index) {
    if (!_resolved) {
      return _selected.contains(index)
          ? OptionState.selected
          : OptionState.neutral;
    }
    if (_q.correct.contains(index)) return OptionState.correct;
    if (_selected.contains(index)) return OptionState.wrong;
    return OptionState.disabled;
  }

  Widget _option(int index) {
    return OptionButton(
      label: _q.options[index],
      state: _stateFor(index),
      onTap: _resolved ? null : () => _tap(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final twoUp = _q.options.length == 2 && !_q.selectAll;
    return PreviewGate(
      preview: _q.preview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          if (_q.seconds != null)
            CountdownBar(
              seconds: _q.seconds!,
              active: !_resolved,
              onDone: () {
                if (_resolved) return;
                _selected.clear();
                _resolve();
              },
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xl,
                children: [
                  PromptBlock(
                    prompt: _q.prompt,
                    instruction: _q.instruction,
                    detail: _q.detail,
                  ),
                  if (twoUp)
                    Row(
                      spacing: AppSpacing.sm,
                      children: [
                        for (var i = 0; i < 2; i++) Expanded(child: _option(i)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < _q.options.length; i++) _option(i),
                      ],
                    ),
                  if (_q.selectAll && !_resolved)
                    FilledButton(
                      onPressed: _selected.isEmpty ? null : _resolve,
                      child: const Text('Check'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
