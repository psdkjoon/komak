import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/hint_typing_question.dart';
import 'package:komak/core/models/questions/matching_question.dart';
import 'package:komak/core/models/questions/memory_question.dart';
import 'package:komak/core/models/questions/multiple_choice_question.dart';
import 'package:komak/core/models/questions/odd_one_out_question.dart';
import 'package:komak/core/models/questions/order_question.dart';
import 'package:komak/core/models/questions/reverse_choice_question.dart';
import 'package:komak/core/models/questions/scramble_question.dart';
import 'package:komak/core/models/questions/self_check_question.dart';
import 'package:komak/core/models/questions/study_question.dart';
import 'package:komak/core/models/questions/text_field_question.dart';
import 'package:komak/core/models/questions/timed_question.dart';
import 'package:komak/core/models/questions/true_false_question.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/services/question_generator.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/celebration_burst.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/theme/app_colors_extension.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/matching_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/memory_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/multiple_choice_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/odd_one_out_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/order_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/reverse_choice_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/scramble_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/self_check_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/text_field_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/timed_widget.dart';
import 'package:komak/features/practice/widgets/question_widgets/true_false_widget.dart';

class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  late final List<StudyQuestion> _questions;
  late final AppController _controller;
  final PracticeFeedbackController _feedback = PracticeFeedbackController();
  int _index = 0;
  int _correctCount = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AppScope.read(context);
    final Deck deck = _controller.deckById(widget.deckId);
    _questions = QuestionGenerator().buildSession(deck);
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _onAnswered(bool correct, List<String> cardIds) async {
    for (final String cardId in cardIds) {
      await _controller.registerCardAttempt(
        widget.deckId,
        cardId,
        wasCorrect: correct,
      );
    }
    if (correct) _correctCount += 1;

    if (_index + 1 >= _questions.length) {
      await _controller.sound.play(AppSound.success);
      await _controller.completeSession();
      if (mounted) setState(() => _finished = true);
    } else if (mounted) {
      setState(() => _index += 1);
    }
  }

  Widget _buildBody(StudyQuestion question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question as MultipleChoiceQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.timed:
        return TimedWidget(
          question: question as TimedQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.textField:
        return TextFieldWidget(
          question: question as TextFieldQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.hintTyping:
        final HintTypingQuestion hinted = question as HintTypingQuestion;
        return TextFieldWidget(
          question: hinted,
          hint: hinted.hint,
          onAnswered: _onAnswered,
        );
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          question: question as TrueFalseQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.reverseChoice:
        return ReverseChoiceWidget(
          question: question as ReverseChoiceQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.scramble:
        return ScrambleWidget(
          question: question as ScrambleQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.selfCheck:
        return SelfCheckWidget(
          question: question as SelfCheckQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.memory:
        return MemoryWidget(
          question: question as MemoryQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.order:
        return OrderWidget(
          question: question as OrderQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.matching:
        return MatchingWidget(
          question: question as MatchingQuestion,
          onAnswered: _onAnswered,
        );
      case QuestionType.oddOneOut:
        return OddOneOutWidget(
          question: question as OddOneOutQuestion,
          onAnswered: _onAnswered,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Deck deck = _controller.deckById(widget.deckId);
    final ThemeData theme = Theme.of(context);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(deck.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: EmptyState(
          icon: Icons.quiz_outlined,
          title: 'Not enough cards yet',
          message: 'Add a few more cards to ${deck.title} to start practicing.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PracticeFeedbackScope(
        controller: _feedback,
        child: PracticeFeedbackLayer(
          controller: _feedback,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppLayout.sessionMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: _finished
                      ? _PracticeSummary(
                          total: _questions.length,
                          correct: _correctCount,
                          accent: deck.accentColor,
                          onDone: () => Navigator.of(context).pop(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  '${_index + 1} / ${_questions.length}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                InfoPill(
                                  icon: _questions[_index].type.icon,
                                  label: _questions[_index].type.label,
                                  color: deck.accentColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: (_index + 1) / _questions.length,
                                ),
                                duration: AppMotion.resolve(
                                  context,
                                  AppMotion.standard,
                                ),
                                curve: AppMotion.emphasizedCurve,
                                builder: (
                                  BuildContext context,
                                  double value,
                                  Widget? child,
                                ) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    color: deck.accentColor,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: AppMotion.resolve(
                                  context,
                                  AppMotion.standard,
                                ),
                                switchInCurve: AppMotion.enterCurve,
                                switchOutCurve: AppMotion.exitCurve,
                                transitionBuilder: (
                                  Widget child,
                                  Animation<double> animation,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.04, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_index),
                                  child: _buildBody(_questions[_index]),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  const _PracticeSummary({
    required this.total,
    required this.correct,
    required this.accent,
    required this.onDone,
  });

  final int total;
  final int correct;
  final Color accent;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double ratio = total == 0 ? 0 : correct / total;
    final bool great = ratio >= 0.8;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (great)
                CelebrationBurst(
                  colors: <Color>[
                    accent,
                    context.appColors.success,
                    theme.colorScheme.tertiary,
                  ],
                ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio),
                duration: AppMotion.resolve(context, Durations.extralong2),
                curve: AppMotion.emphasizedCurve,
                builder: (BuildContext context, double value, Widget? child) {
                  return SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          color: accent,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHigh,
                        ),
                        Text(
                          '${(value * 100).round()}%',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            great ? 'Great work!' : 'Session complete',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$correct of $total correct',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }
}
