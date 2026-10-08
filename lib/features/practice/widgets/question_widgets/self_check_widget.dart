import 'package:flutter/material.dart';
import 'package:komak/core/models/questions/self_check_question.dart';
import 'package:komak/core/theme/app_colors_extension.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/prompt_card.dart';

class SelfCheckWidget extends StatefulWidget {
  const SelfCheckWidget(
      {super.key, required this.question, required this.onAnswered,});

  final SelfCheckQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<SelfCheckWidget> createState() => _SelfCheckWidgetState();
}

class _SelfCheckWidgetState extends State<SelfCheckWidget> {
  bool _revealed = false;
  bool _rated = false;

  void _rate(bool correct) {
    if (_rated) return;
    setState(() => _rated = true);
    PracticeFeedback.report(context, correct);
    Future<void>.delayed(
        PracticeFeedback.answerDelay(context, correct, Durations.long2), () {
      if (mounted) {
        widget.onAnswered(correct, <String>[widget.question.card.id]);
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
          PromptCard(
            text: widget.question.card.front,
            trailing: Text(
              'Try to recall the answer first',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.standard),
            child: !_revealed
                ? FilledButton.tonalIcon(
                    key: const ValueKey<String>('reveal'),
                    onPressed: () => setState(() => _revealed = true),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Show answer'),
                  )
                : Column(
                    key: const ValueKey<String>('rate'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.6),),
                        ),
                        child: Text(widget.question.card.back,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _rated ? null : () => _rate(false),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Not yet'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: scheme.error,),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _rated ? null : () => _rate(true),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Got it'),
                              style: FilledButton.styleFrom(
                                backgroundColor: context.appColors.success,
                                foregroundColor: context.appColors.onSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
