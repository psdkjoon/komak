import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/text_normalizer.dart';
import 'package:komak/core/typo_check.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/prompt_card.dart';
import 'package:komak/ui/widgets/question/question_parts.dart';
import 'package:komak/ui/widgets/shake_view.dart';

class TypeView extends StatefulWidget {
  const TypeView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final TypeQuestion question;
  final ResolveCallback onResolved;

  @override
  State<TypeView> createState() => _TypeViewState();
}

class _TypeViewState extends State<TypeView> {
  static const double _fieldMaxWidth = 420;
  static const double _maskSpacing = 2;
  static const double _focusedBorderWidth = 2;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool? _isCorrect;
  int _shakeTrigger = 0;

  TypeQuestion get _q => widget.question;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _matches(String input) {
    for (final answer in _q.answers) {
      if (answersMatch(input, answer)) return true;
      if (_q.tolerant && answersClose(input, answer)) return true;
    }
    return false;
  }

  void _finish(bool correct) {
    if (_isCorrect != null) return;
    setState(() {
      _isCorrect = correct;
      if (!correct) _shakeTrigger++;
    });
    widget.onResolved(
      correct ? <String>{} : _q.cardIds.toSet(),
      note: _q.reveal,
    );
  }

  void _submit() {
    if (_isCorrect != null || _controller.text.trim().isEmpty) return;
    _finish(_matches(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final resultColor = _isCorrect == null
        ? scheme.primary
        : (_isCorrect! ? scheme.secondary : scheme.error);

    return PreviewGate(
      preview: _q.preview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          if (_q.seconds != null)
            CountdownBar(
              seconds: _q.seconds!,
              active: _isCorrect == null,
              onDone: () {
                if (_isCorrect == null) _finish(false);
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
                spacing: AppSpacing.md,
                children: [
                  if (_q.instruction != null)
                    Text(
                      _q.instruction!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  PromptCard(text: _q.prompt),
                  if (_q.mask != null)
                    Text.verbatim(
                      _q.mask!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        letterSpacing: _maskSpacing,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _fieldMaxWidth),
                      child: ShakeView(
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
                            hintText: 'Type your answer'.tr,
                            suffixIcon: _isCorrect == null
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                    onPressed: _submit,
                                  )
                                : Icon(
                                    _isCorrect!
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: resultColor,
                                  ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.tile),
                              borderSide: BorderSide(
                                color: resultColor,
                                width: _focusedBorderWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isCorrect == null)
                    TextButton(
                      onPressed: () => _finish(false),
                      child: const Text('I do not know'),
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
