import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/questions/odd_one_out_question.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';

class OddOneOutWidget extends StatefulWidget {
  const OddOneOutWidget(
      {super.key, required this.question, required this.onAnswered,});

  final OddOneOutQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<OddOneOutWidget> createState() => _OddOneOutWidgetState();
}

class _OddOneOutWidgetState extends State<OddOneOutWidget> {
  String? _selectedId;

  void _select(Flashcard card) {
    if (_selectedId != null) return;
    final bool correct = card.id == widget.question.imposterId;
    setState(() => _selectedId = card.id);
    PracticeFeedback.report(context, correct);
    Future<void>.delayed(
        PracticeFeedback.answerDelay(context, correct, Durations.long2), () {
      if (mounted) {
        widget.onAnswered(correct,
            widget.question.options.map((Flashcard c) => c.id).toList(),);
      }
    });
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
          Text('Which one does not belong?',
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center,),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.3,
            children: widget.question.options.map((Flashcard card) {
              final bool isImposter = card.id == widget.question.imposterId;
              final bool isSelected = card.id == _selectedId;
              Color background = scheme.surfaceContainer;
              Color border = scheme.outlineVariant;

              if (_selectedId != null) {
                if (isImposter) {
                  background = scheme.secondaryContainer;
                  border = scheme.secondary;
                } else if (isSelected) {
                  background = scheme.errorContainer;
                  border = scheme.error;
                }
              }

              return AnimatedContainer(
                duration: AppMotion.resolve(context, AppMotion.standard),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: border, width: 1.6),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: _selectedId == null ? () => _select(card) : null,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(card.front,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall,),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
