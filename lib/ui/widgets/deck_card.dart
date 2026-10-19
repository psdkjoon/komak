import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/card_intake.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/widgets/charts/stage_bar_view.dart';
import 'package:komak/ui/widgets/deck_icon_view.dart';
import 'package:komak/ui/widgets/info_pill.dart';
import 'package:komak/ui/widgets/mastery_ring_view.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.deck,
    required this.onLearn,
    required this.onStudy,
    required this.onPractice,
    required this.onPracticeSettings,
    required this.onEdit,
  });

  final Deck deck;
  final VoidCallback onLearn;
  final VoidCallback onStudy;
  final VoidCallback onPractice;
  final VoidCallback onPracticeSettings;
  final VoidCallback onEdit;

  static const double _badgeSize = 64;
  static const double _ringSize = 48;
  static const double _typeChipSize = 32;
  static const double _typeIconSize = 17;
  static const double _actionIconSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = deck.accentColor;
    final hasCards = deck.cards.isNotEmpty;
    final playable = <PracticeSection>[
      for (final section in PracticeSection.values)
        if (deck.playableKinds.any((PracticeKind k) => k.section == section))
          section,
    ];
    final status = theme.extension<StatusColors>()!;
    final hasLearnable = deck.dueCount + deck.newCount > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.2),
            scheme.surfaceContainer,
          ],
          stops: const [0, 0.75],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          Row(
            children: [
              Hero(
                tag: 'deck-badge-${deck.id}',
                child: DeckIconView(
                  iconKey: deck.iconKey,
                  color: accent,
                  size: _badgeSize,
                ),
              ),
              const Spacer(),
              if (deck.totalAttempts > 0)
                MasteryRingView(
                  value: deck.overallAccuracy,
                  color: accent,
                  size: _ringSize,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Text.verbatim(deck.title, style: theme.textTheme.headlineSmall),
              if (deck.description.isNotEmpty)
                Text.verbatim(
                  deck.description,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              InfoPill(
                icon: Icons.style_rounded,
                label: '${deck.cards.length}/$maxCardsPerDeck cards',
                color: accent,
              ),
              if (hasCards)
                InfoPill(
                  icon: Icons.schedule_rounded,
                  label: '${deck.dueCount} due',
                  color: deck.dueCount > 0 ? status.warning : null,
                ),
              if (hasCards)
                InfoPill(
                  icon: Icons.fiber_new_rounded,
                  label: '${deck.newCount} new',
                  color: deck.newCount > 0 ? status.info : null,
                ),
              InfoPill(
                icon: Icons.bolt_rounded,
                label: deck.practiceLength == endlessPractice
                    ? 'Endless practice'
                    : '${deck.practiceLength} per practice',
              ),
            ],
          ),
          if (hasCards)
            StageBarView(
              counts: {
                for (final stage in CardStage.values)
                  stage: deck.countStage(stage),
              },
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              spacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasLearnable ? onLearn : null,
                    icon: const Icon(Icons.school_rounded),
                    label: Text(hasLearnable ? 'Learn' : 'Nothing due today'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: hasCards ? onStudy : null,
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: const Text('Study cards'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: hasCards ? onPractice : null,
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text('Practice'),
                  ),
                ),
              ],
            ),
          ),
          if (hasCards)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final section in playable)
                  Tooltip(
                    message: section.label.tr,
                    child: Container(
                      width: _typeChipSize,
                      height: _typeChipSize,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        section.icon,
                        size: _typeIconSize,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: onPracticeSettings,
                icon: const Icon(Icons.tune_rounded, size: _actionIconSize),
                label: const Text('Practice settings'),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: _actionIconSize),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
