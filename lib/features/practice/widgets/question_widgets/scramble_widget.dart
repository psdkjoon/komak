import 'package:flutter/material.dart';
import 'package:komak/core/models/questions/scramble_question.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/prompt_card.dart';

class ScrambleWidget extends StatefulWidget {
  const ScrambleWidget(
      {super.key, required this.question, required this.onAnswered,});

  final ScrambleQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<ScrambleWidget> createState() => _ScrambleWidgetState();
}

class _ScrambleWidgetState extends State<ScrambleWidget> {
  final List<int> _chosen = <int>[];
  bool? _isCorrect;

  void _add(int index) {
    if (_isCorrect != null || _chosen.contains(index)) return;
    setState(() => _chosen.add(index));
    if (_chosen.length == widget.question.letters.length) {
      final String attempt =
          _chosen.map((int i) => widget.question.letters[i]).join();
      final bool correct = attempt == widget.question.target;
      setState(() => _isCorrect = correct);
      PracticeFeedback.report(context, correct);
      Future<void>.delayed(
          PracticeFeedback.answerDelay(context, correct, Durations.extralong1),
          () {
        if (mounted) {
          widget.onAnswered(correct, <String>[widget.question.card.id]);
        }
      });
    }
  }

  void _remove(int position) {
    if (_isCorrect != null) return;
    setState(() => _chosen.removeAt(position));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<String> letters = widget.question.letters;
    final Color slotColor = _isCorrect == null
        ? scheme.primary
        : (_isCorrect! ? scheme.secondary : scheme.error);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PromptCard(
            text: widget.question.card.front,
            trailing: Text(
              'Unscramble the answer',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (int slot = 0; slot < letters.length; slot++)
                _LetterBox(
                  letter: slot < _chosen.length ? letters[_chosen[slot]] : '',
                  color: slotColor,
                  filled: slot < _chosen.length,
                  onTap: slot < _chosen.length ? () => _remove(slot) : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (int i = 0; i < letters.length; i++)
                _LetterBox(
                  letter: letters[i],
                  color: scheme.primary,
                  filled: false,
                  raised: true,
                  hidden: _chosen.contains(i),
                  onTap: () => _add(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.quick),
            child: _isCorrect == null
                ? const SizedBox(height: 20)
                : Text(
                    _isCorrect!
                        ? 'Correct!'
                        : 'Correct answer: ${widget.question.card.back}',
                    key: ValueKey<bool>(_isCorrect!),
                    textAlign: TextAlign.center,
                    style:
                        theme.textTheme.titleSmall?.copyWith(color: slotColor),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LetterBox extends StatelessWidget {
  const _LetterBox({
    required this.letter,
    required this.color,
    required this.filled,
    required this.onTap,
    this.raised = false,
    this.hidden = false,
  });

  final String letter;
  final Color color;
  final bool filled;
  final bool raised;
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Opacity(
      opacity: hidden ? 0.2 : 1,
      child: Material(
        color: raised
            ? scheme.surfaceContainerHigh
            : (filled ? color.withValues(alpha: 0.18) : Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
              color: raised ? scheme.outlineVariant : color,
              width: filled || raised ? 1.6 : 1,),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: hidden ? null : onTap,
          child: SizedBox(
            width: 42,
            height: 50,
            child: Center(
              child:
                  Text(letter.toUpperCase(), style: theme.textTheme.titleLarge),
            ),
          ),
        ),
      ),
    );
  }
}
