import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/info_pill.dart';
import 'package:komak/ui/widgets/pressable_view.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.accent,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  final Flashcard card;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  static const double _deleteIconSize = 18;
  static const double _selectedBorder = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PressableView(
      onTap: onTap,
      onLongPress: onLongPress,
      playSound: false,
      hoverScale: 1.015,
      semanticLabel: card.front,
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(
            color: selected ? accent : scheme.outlineVariant,
            width: selected ? _selectedBorder : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text.verbatim(
                      card.front,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: _deleteIconSize + 4,
                      color: selected ? accent : scheme.onSurfaceVariant,
                    ),
                  )
                else
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete card'.tr,
                    visualDensity: VisualDensity.compact,
                    iconSize: _deleteIconSize,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((card.reading ?? '').isNotEmpty)
                      Text.verbatim(
                        card.reading!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text.verbatim(
                      card.back,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (card.orderIndex != null ||
                (card.groupId != null && card.groupId!.isNotEmpty))
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: [
                  if (card.orderIndex != null)
                    InfoPill(
                      icon: Icons.tag_rounded,
                      label: '${card.orderIndex}',
                      color: accent,
                      translate: false,
                    ),
                  if (card.groupId != null && card.groupId!.isNotEmpty)
                    InfoPill(
                      icon: Icons.folder_outlined,
                      label: card.groupId!,
                      color: scheme.onSurfaceVariant,
                      translate: false,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
