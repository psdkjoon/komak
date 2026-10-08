import 'package:flutter/material.dart';
import 'package:komak/core/models/questions/multiple_choice_question.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/option_button.dart';
import 'package:komak/features/practice/widgets/question_widgets/prompt_card.dart';

class MultipleChoiceWidget extends StatefulWidget {
  const MultipleChoiceWidget(
      {super.key, required this.question, required this.onAnswered,});

  final MultipleChoiceQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  int? _selectedIndex;

  void _select(int index) {
    if (_selectedIndex != null) return;
    final bool correct = index == widget.question.correctIndex;
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
    return SingleChildScrollView(
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
              onTap: _selectedIndex == null ? () => _select(i) : null,
            ),
        ],
      ),
    );
  }

  OptionState _stateFor(int index) {
    if (_selectedIndex == null) return OptionState.neutral;
    if (index == widget.question.correctIndex) return OptionState.correct;
    if (index == _selectedIndex) return OptionState.wrong;
    return OptionState.disabled;
  }
}
