import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/question/prompt_card.dart';

class MeetView extends StatelessWidget {
  const MeetView({
    required this.question,
    required this.onResolved,
    super.key,
  });

  final MeetQuestion question;
  final ResolveCallback onResolved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final card = question.card;
    final extras = <String>[
      if (card.reading != null && card.reading!.trim().isNotEmpty) card.reading!,
      if (card.example != null && card.example!.trim().isNotEmpty) card.example!,
      if (card.note != null && card.note!.trim().isNotEmpty) card.note!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
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
                Text(
                  'A new card. Take a look before we practice it.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                PromptCard(text: card.front),
                PromptCard(text: card.back),
                for (final line in extras)
                  Text.verbatim(
                    line,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
        FilledButton(
          onPressed: () => onResolved(<String>{}),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
