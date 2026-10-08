import 'package:flutter/material.dart';
import 'package:komak/core/models/questions/text_field_question.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/shake_widget.dart';
import 'package:komak/features/practice/practice_feedback.dart';
import 'package:komak/features/practice/widgets/question_widgets/prompt_card.dart';

class TextFieldWidget extends StatefulWidget {
  const TextFieldWidget(
      {super.key, required this.question, required this.onAnswered, this.hint,});

  final TextFieldQuestion question;
  final String? hint;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool? _isCorrect;
  int _shakeTrigger = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isCorrect != null || _controller.text.trim().isEmpty) return;
    final bool correct = widget.question.isAnswerCorrect(_controller.text);
    setState(() {
      _isCorrect = correct;
      if (!correct) _shakeTrigger++;
    });
    PracticeFeedback.report(context, correct);
    Future<void>.delayed(
        PracticeFeedback.answerDelay(context, correct, Durations.extralong1),
        () {
      if (mounted) {
        widget.onAnswered(correct, <String>[widget.question.card.id]);
      }
    });
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
          PromptCard(text: widget.question.card.front),
          if (widget.hint != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.hint!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(letterSpacing: 2, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ShakeWidget(
                trigger: _shakeTrigger,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  enabled: _isCorrect == null,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Type your answer',
                    suffixIcon: _isCorrect == null
                        ? IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded),
                            onPressed: _submit,)
                        : Icon(
                            _isCorrect!
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: resultColor,),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: resultColor, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: resultColor),
                  ),
          ),
        ],
      ),
    );
  }
}
