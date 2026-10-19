import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/deck.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/widgets/deck_icon_view.dart';
import 'package:komak/ui/widgets/info_pill.dart';
import 'package:komak/ui/widgets/mastery_ring_view.dart';
import 'package:komak/ui/widgets/pressable_view.dart';

class DeckTile extends StatelessWidget {
  const DeckTile({
    super.key,
    required this.deck,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.heroEnabled = true,
    this.selecting = false,
    this.selected = false,
  });

  final Deck deck;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final bool heroEnabled;
  final bool selecting;
  final bool selected;

  static const double _badgeSize = 36;
  static const double _ringSize = 30;
  static const double _checkSize = 26;
  static const double _cardsIconSize = 13;
  static const double _selectedBorder = 2.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = deck.accentColor;

    final badge = DeckIconView(
      iconKey: deck.iconKey,
      color: accent,
      size: _badgeSize,
    );

    return PressableView(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      semanticLabel: deck.title,
      child: AnimatedContainer(
        duration: AppMotion.resolve(context, AppMotion.quick),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.32),
            width: selected ? _selectedBorder : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: selected ? 0.34 : 0.16),
              scheme.surfaceContainer,
            ],
            stops: const [0, 0.7],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                heroEnabled && !selecting
                    ? Hero(tag: 'deck-badge-${deck.id}', child: badge)
                    : badge,
                const Spacer(),
                if (selecting)
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: _checkSize,
                    color: selected ? accent : scheme.onSurfaceVariant,
                  )
                else if (deck.dueCount > 0)
                  InfoPill(
                    icon: Icons.schedule_rounded,
                    label: '${deck.dueCount} due',
                    color: theme.extension<StatusColors>()!.warning,
                  )
                else if (deck.totalAttempts > 0)
                  MasteryRingView(
                    value: deck.overallAccuracy,
                    color: accent,
                    size: _ringSize,
                  )
                else
                  InfoPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'New',
                    color: accent,
                  ),
              ],
            ),
            Text.verbatim(
              deck.title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(
              child: deck.description.isEmpty
                  ? Text(
                      'No description yet.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text.verbatim(
                      deck.description,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Row(
              spacing: AppSpacing.xxs,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: _cardsIconSize,
                  color: scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    '${deck.cards.length} cards',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
