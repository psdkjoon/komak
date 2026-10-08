import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/questions/order_question.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/shake_widget.dart';
import 'package:komak/features/practice/practice_feedback.dart';

class OrderWidget extends StatefulWidget {
  const OrderWidget(
      {super.key, required this.question, required this.onAnswered,});

  final OrderQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<OrderWidget> createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  final List<Flashcard> _chosen = <Flashcard>[];
  late List<Flashcard> _remaining;
  bool? _isCorrect;
  int _shakeTrigger = 0;

  @override
  void initState() {
    super.initState();
    _remaining = List<Flashcard>.from(widget.question.shuffledItems);
  }

  void _pick(Flashcard card) {
    if (_isCorrect != null) return;
    setState(() {
      _remaining.remove(card);
      _chosen.add(card);
    });
    AppScope.read(context).sound.play(AppSound.tap);
    if (_remaining.isEmpty) {
      final bool correct = widget.question
          .isOrderCorrect(_chosen.map((Flashcard c) => c.id).toList());
      setState(() {
        _isCorrect = correct;
        if (!correct) _shakeTrigger++;
      });
      PracticeFeedback.report(context, correct);
      Future<void>.delayed(
          PracticeFeedback.answerDelay(context, correct, Durations.extralong1),
          () {
        if (mounted) {
          widget.onAnswered(
              correct,
              widget.question.shuffledItems
                  .map((Flashcard c) => c.id)
                  .toList(),);
        }
      });
    }
  }

  void _undo() {
    if (_isCorrect != null || _chosen.isEmpty) return;
    setState(() => _remaining.add(_chosen.removeLast()));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color resultColor = _isCorrect == null
        ? scheme.primary
        : (_isCorrect! ? scheme.secondary : scheme.error);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Tap the pieces in the right order',
              style: theme.textTheme.titleSmall, textAlign: TextAlign.center,),
          const SizedBox(height: AppSpacing.md),
          ShakeWidget(
            trigger: _shakeTrigger,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: List<Widget>.generate(
                  widget.question.shuffledItems.length, (int index) {
                final bool filled = index < _chosen.length;
                return AnimatedContainer(
                  duration: AppMotion.resolve(context, AppMotion.quick),
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled
                        ? resultColor.withValues(alpha: 0.16)
                        : scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: filled ? resultColor : scheme.outlineVariant,
                        width: filled ? 1.6 : 1,),
                  ),
                  child: filled
                      ? Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _chosen[index].front,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: resultColor),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Text('${index + 1}',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: _remaining.map((Flashcard card) {
              return ActionChip(
                onPressed: () => _pick(card),
                label: Text(card.front),
                backgroundColor: scheme.surfaceContainer,
                side: BorderSide(color: scheme.outlineVariant),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs,),
              );
            }).toList(),
          ),
          if (_isCorrect == null)
            TextButton.icon(
              onPressed: _chosen.isEmpty ? null : _undo,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Undo last'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                _isCorrect! ? 'Nailed the order!' : 'Not quite the right order',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(color: resultColor),
              ),
            ),
        ],
      ),
    );
  }
}
