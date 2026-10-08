import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/pressable_scale.dart';

class DeckTile extends StatelessWidget {
  const DeckTile({
    super.key,
    required this.deck,
    required this.onTap,
    this.heroEnabled = true,
  });

  final Deck deck;
  final VoidCallback onTap;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = deck.accentColor;

    final Widget badge =
        DeckIconBadge(iconKey: deck.iconKey, color: accent, size: 48);

    return PressableScale(
      onTap: onTap,
      semanticLabel: deck.title,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              accent.withValues(alpha: 0.16),
              scheme.surfaceContainer,
            ],
            stops: const <double>[0, 0.7],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                heroEnabled
                    ? Hero(tag: 'deck-badge-${deck.id}', child: badge)
                    : badge,
                const Spacer(),
                if (deck.totalAttempts > 0)
                  MasteryRing(
                    value: deck.overallAccuracy,
                    color: accent,
                    size: 38,
                  )
                else
                  InfoPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'New',
                    color: accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              deck.title,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Expanded(
              child: Text(
                deck.description.isEmpty
                    ? 'No description yet.'
                    : deck.description,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Icon(
                  Icons.style_outlined,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${deck.cards.length} cards',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
