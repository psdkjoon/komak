import 'package:flutter/material.dart';
import 'package:komak/core/models/questions/true_false_question.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/option_button.dart';
import 'package:komak/features/practice/widgets/question_widgets/prompt_card.dart';

class TrueFalseWidget extends StatefulWidget {
  const TrueFalseWidget(
      {super.key, required this.question, required this.onAnswered,});

  final TrueFalseQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  bool? _answer;

  void _select(bool value) {
    if (_answer != null) return;
    final bool correct = value == widget.question.isTrue;
    setState(() => _answer = value);
    PracticeFeedback.report(context, correct);
    Future<void>.delayed(
        PracticeFeedback.answerDelay(context, correct, Durations.long2), () {
      if (mounted) {
        widget.onAnswered(correct, <String>[widget.question.card.id]);
      }
    });
  }

  OptionState _stateFor(bool value) {
    if (_answer == null) return OptionState.neutral;
    if (value == widget.question.isTrue) return OptionState.correct;
    if (_answer == value) return OptionState.wrong;
    return OptionState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PromptCard(text: widget.question.card.front),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: <Widget>[
                Text('Is this the answer?',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),),
                const SizedBox(height: AppSpacing.xs),
                Text(widget.question.shownAnswer,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OptionButton(
            label: 'True',
            leading: const Icon(Icons.check_rounded),
            state: _stateFor(true),
            onTap: _answer == null ? () => _select(true) : null,
          ),
          OptionButton(
            label: 'False',
            leading: const Icon(Icons.close_rounded),
            state: _stateFor(false),
            onTap: _answer == null ? () => _select(false) : null,
          ),
          AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.quick),
            child: _answer != null && _answer != widget.question.isTrue
                ? Padding(
                    key: const ValueKey<String>('actual'),
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Actual answer: ${widget.question.card.back}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: scheme.error),
                    ),
                  )
                : const SizedBox(key: ValueKey<String>('none'), height: 0),
          ),
        ],
      ),
    );
  }
}
