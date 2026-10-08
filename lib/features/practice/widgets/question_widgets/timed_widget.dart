import 'package:flutter/material.dart';
import 'package:komak/core/models/questions/timed_question.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/option_button.dart';
import 'package:komak/features/practice/widgets/question_widgets/prompt_card.dart';

class TimedWidget extends StatefulWidget {
  const TimedWidget(
      {super.key, required this.question, required this.onAnswered,});

  final TimedQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<TimedWidget> createState() => _TimedWidgetState();
}

class _TimedWidgetState extends State<TimedWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;
  int? _selectedIndex;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
        vsync: this,
        duration: Duration(seconds: widget.question.durationSeconds),)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed && !_resolved) _resolve(null);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timer.isAnimating && !_resolved) {
      if (AppMotion.isReduced(context)) {
        Future<void>.delayed(const Duration(seconds: 4), () {
          if (mounted && !_resolved) _resolve(null);
        });
      } else {
        _timer.forward();
      }
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _resolve(int? index) {
    if (_resolved) return;
    _resolved = true;
    _timer.stop();
    final bool correct = index != null && index == widget.question.correctIndex;
    setState(() => _selectedIndex = index);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedBuilder(
            animation: _timer,
            builder: (BuildContext context, Widget? child) {
              final double remaining = 1 - _timer.value;
              return LinearProgressIndicator(
                value: remaining,
                minHeight: 8,
                color: remaining < 0.3
                    ? theme.colorScheme.error
                    : theme.colorScheme.tertiary,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PromptCard(text: widget.question.card.front),
                const SizedBox(height: AppSpacing.lg),
                for (int i = 0; i < widget.question.options.length; i++)
                  OptionButton(
                    label: widget.question.options[i],
                    state: _stateFor(i),
                    onTap: _resolved ? null : () => _resolve(i),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  OptionState _stateFor(int index) {
    if (!_resolved) return OptionState.neutral;
    if (index == widget.question.correctIndex) return OptionState.correct;
    if (index == _selectedIndex) return OptionState.wrong;
    return OptionState.disabled;
  }
}
