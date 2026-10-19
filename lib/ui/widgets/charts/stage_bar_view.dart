import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';

class StageBarView extends StatelessWidget {
  const StageBarView({
    super.key,
    required this.counts,
    this.showLegend = true,
    this.height = _defaultHeight,
  });

  final Map<CardStage, int> counts;
  final bool showLegend;
  final double height;

  static const double _defaultHeight = 12;
  static const double _dotSize = 10;

  static Color colorOf(CardStage stage, BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    return switch (stage) {
      CardStage.fresh => theme.colorScheme.outline,
      CardStage.learning => status.warning,
      CardStage.young => status.info,
      CardStage.mature => status.success,
    };
  }

  static String labelOf(CardStage stage) => switch (stage) {
        CardStage.fresh => 'New',
        CardStage.learning => 'Learning',
        CardStage.young => 'Young',
        CardStage.mature => 'Mature',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold(0, (int sum, int v) => sum + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: height,
            child: total == 0
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: const SizedBox.expand(),
                  )
                : Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      for (final stage in CardStage.values)
                        if ((counts[stage] ?? 0) > 0)
                          Expanded(
                            flex: counts[stage]!,
                            child: ColoredBox(
                              color: colorOf(stage, context),
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ],
                  ),
          ),
        ),
        if (showLegend)
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final stage in CardStage.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xxs,
                  children: [
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        color: colorOf(stage, context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      labelOf(stage),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text.verbatim(
                      '${counts[stage] ?? 0}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}
