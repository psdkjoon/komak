import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/prompt_card.dart';
import 'package:komak/ui/widgets/question/question_parts.dart';

class FlashView extends StatefulWidget {
  const FlashView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final FlashQuestion question;
  final ResolveCallback onResolved;

  @override
  State<FlashView> createState() => _FlashViewState();
}

class _FlashViewState extends State<FlashView> {
  late bool _canReveal = widget.question.thinkSeconds == 0;
  bool _revealed = false;
  bool _resolved = false;

  FlashQuestion get _q => widget.question;

  void _rate({required bool knew}) {
    if (_resolved) return;
    setState(() => _resolved = true);
    widget.onResolved(knew ? <String>{} : _q.cardIds.toSet());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        if (_q.thinkSeconds > 0 && !_revealed)
          CountdownBar(
            seconds: _q.thinkSeconds,
            onDone: () {
              if (mounted) setState(() => _canReveal = true);
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
                PromptBlock(prompt: _q.prompt, instruction: _q.instruction),
                AnimatedSwitcher(
                  duration: AppMotion.resolve(context, AppMotion.standard),
                  child: _revealed
                      ? Column(
                          key: const ValueKey<bool>(true),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.sm,
                          children: [
                            PromptCard(text: _q.answer),
                            for (final line in _q.details)
                              Text.verbatim(
                                line,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey<bool>(false)),
                ),
              ],
            ),
          ),
        ),
        if (!_revealed)
          FilledButton(
            onPressed:
                _canReveal ? () => setState(() => _revealed = true) : null,
            child: const Text('Show answer'),
          )
        else
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resolved ? null : () => _rate(knew: false),
                  child: const Text('Not yet'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _resolved ? null : () => _rate(knew: true),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
