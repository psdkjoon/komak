import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/common_widgets.dart';

class DeckPanel extends StatelessWidget {
  const DeckPanel({
    super.key,
    required this.deck,
    required this.onStudy,
    required this.onPractice,
    required this.onPracticeSettings,
    required this.onEdit,
  });

  final Deck deck;
  final VoidCallback onStudy;
  final VoidCallback onPractice;
  final VoidCallback onPracticeSettings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = deck.accentColor;
    final bool hasCards = deck.cards.isNotEmpty;
    final List<QuestionType> playable = deck.playableTypes;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.2),
            scheme.surfaceContainer,
          ],
          stops: const <double>[0, 0.75],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Hero(
                tag: 'deck-badge-${deck.id}',
                child: DeckIconBadge(
                  iconKey: deck.iconKey,
                  color: accent,
                  size: 64,
                ),
              ),
              const Spacer(),
              if (deck.totalAttempts > 0)
                MasteryRing(
                  value: deck.overallAccuracy,
                  color: accent,
                  size: 48,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(deck.title, style: theme.textTheme.headlineSmall),
          if (deck.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              deck.description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              InfoPill(
                icon: Icons.style_rounded,
                label: '${deck.cards.length} cards',
                color: accent,
              ),
              InfoPill(
                icon: Icons.bolt_rounded,
                label: '${deck.practiceLength} per practice',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasCards ? onStudy : null,
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('Study cards'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: hasCards ? onPractice : null,
              icon: const Icon(Icons.quiz_rounded),
              label: const Text('Practice'),
            ),
          ),
          if (hasCards) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final QuestionType type in playable)
                  Tooltip(
                    message: type.label,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type.icon,
                        size: 17,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (playable.isEmpty)
                  Text(
                    'Type-the-answer questions',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: onPracticeSettings,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Practice settings'),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
