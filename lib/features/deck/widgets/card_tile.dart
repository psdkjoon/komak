import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/pressable_scale.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.accent,
    required this.onTap,
    required this.onDelete,
  });

  final Flashcard card;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return PressableScale(
      onTap: onTap,
      playSound: false,
      hoverScale: 1.015,
      semanticLabel: card.front,
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
          right: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      card.front,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete card',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  card.back,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (card.orderIndex != null ||
                (card.groupId != null && card.groupId!.isNotEmpty))
              Wrap(
                spacing: AppSpacing.xxs,
                children: <Widget>[
                  if (card.orderIndex != null)
                    InfoPill(
                      icon: Icons.tag_rounded,
                      label: '${card.orderIndex}',
                      color: accent,
                    ),
                  if (card.groupId != null && card.groupId!.isNotEmpty)
                    InfoPill(
                      icon: Icons.folder_outlined,
                      label: card.groupId!,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
