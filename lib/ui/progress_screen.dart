import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/decks/study_stats.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/deck_detail_screen.dart';
import 'package:komak/ui/widgets/chart_card.dart';
import 'package:komak/ui/widgets/charts/bar_chart_view.dart';
import 'package:komak/ui/widgets/charts/heatmap_view.dart';
import 'package:komak/ui/widgets/charts/line_chart_view.dart';
import 'package:komak/ui/widgets/charts/stage_bar_view.dart';
import 'package:komak/ui/widgets/deck_icon_view.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/stat_tile.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const int _activityDays = 14;
  static const int _accuracyDays = 30;
  static const int _forecastDays = 7;
  static const int _heatmapDays = 84;
  static const double _deckIcon = 40;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _daysAgo(DateTime today, int days) =>
      DateTime(today.year, today.month, today.day - days);

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = theme.extension<StatusColors>()!;
    final stats = controller.stats;
    final today = _today();
    final decks = controller.decks;
    final cards = [for (final deck in decks) ...deck.cards];

    final activity = [
      for (var i = _activityDays - 1; i >= 0; i--) stats.on(_daysAgo(today, i)),
    ];
    final accuracy = [
      for (var i = _accuracyDays - 1; i >= 0; i--)
        _accuracyOf(stats.on(_daysAgo(today, i))),
    ];
    final heat = [
      for (var i = _heatmapDays - 1; i >= 0; i--)
        stats.on(_daysAgo(today, i)).reviews,
    ];
    final forecast = _forecast(cards, today);
    final stageCounts = {
      for (final stage in CardStage.values)
        stage: cards.where((c) => c.stage == stage).length,
    };

    final todayStats = stats.on(today);
    final week = [
      for (var i = 0; i < 7; i++) stats.on(_daysAgo(today, i)),
    ];
    final weekReviews = week.fold(0, (int sum, DayStats d) => sum + d.reviews);
    final weekCorrect = week.fold(0, (int sum, DayStats d) => sum + d.correct);
    final weekPercent =
        weekReviews == 0 ? 0 : (weekCorrect * 100 / weekReviews).round();

    final sortedDecks = [...decks.where((d) => d.cards.isNotEmpty)]
      ..sort((a, b) => b.dueCount.compareTo(a.dueCount));

    if (cards.isEmpty && stats.totalReviews == 0) {
      return const PageFrame(
        child: EmptyStateView(
          icon: Icons.insights_rounded,
          title: 'No progress yet',
          message:
              'Add a deck and start a Learn session. Your graphs will show up here.',
        ),
      );
    }

    return PageFrame(
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text('Progress', style: theme.textTheme.headlineMedium),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatTile(
                icon: Icons.local_fire_department_rounded,
                color: status.streak,
                value: controller.streak.currentStreak,
                label: 'day streak',
              ),
              StatTile(
                icon: Icons.bolt_rounded,
                color: scheme.primary,
                value: todayStats.reviews,
                label: 'reviews today',
              ),
              StatTile(
                icon: Icons.schedule_rounded,
                color: status.warning,
                value: controller.totalDue,
                label: 'due now',
              ),
              StatTile(
                icon: Icons.workspace_premium_rounded,
                color: status.success,
                value: stageCounts[CardStage.mature] ?? 0,
                label: 'mature cards',
              ),
            ],
          ),
          if (stats.totalReviews == 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Start a Learn session from any deck to fill these graphs.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Column(
            spacing: AppSpacing.md,
            children: [
              ChartCard(
                title: 'Reviews per day',
                subtitle: 'Last 14 days, solid part is what you remembered',
                child: BarChartView(
                  values: [for (final d in activity) d.reviews.toDouble()],
                  overlay: [for (final d in activity) d.correct.toDouble()],
                  labels: [
                    for (var i = 0; i < _activityDays; i++)
                      i.isEven
                          ? '${_daysAgo(today, _activityDays - 1 - i).day}'
                          : '',
                  ],
                  color: scheme.primary,
                ),
              ),
              ChartCard(
                title: 'Memory accuracy',
                subtitle: L10n.fmt(
                  'Last 7 days: {}% remembered',
                  [weekPercent],
                ),
                child: LineChartView(values: accuracy, color: status.success),
              ),
              ChartCard(
                title: 'Coming up',
                subtitle: 'Cards due over the next 7 days',
                child: BarChartView(
                  values: forecast,
                  labels: [
                    for (var i = 0; i < _forecastDays; i++)
                      i == 0
                          ? 'Today'.tr
                          : '${today.add(Duration(days: i)).day}',
                  ],
                  color: status.warning,
                ),
              ),
              ChartCard(
                title: 'How well you know your cards',
                subtitle: 'New cards become mature after about three weeks',
                child: StageBarView(counts: stageCounts),
              ),
              ChartCard(
                title: 'Activity',
                subtitle: 'Last 12 weeks, darker means more reviews',
                child: HeatmapView(
                  counts: heat,
                  firstDay: _daysAgo(today, _heatmapDays - 1),
                  color: scheme.primary,
                ),
              ),
              if (sortedDecks.isNotEmpty)
                ChartCard(
                  title: 'Decks',
                  child: Column(
                    spacing: AppSpacing.lg,
                    children: [
                      for (final deck in sortedDecks)
                        _DeckRow(
                          deck: deck,
                          onTap: () => unawaited(
                            AppRoutes.push<void>(
                              context,
                              DeckDetailScreen(deckId: deck.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static double? _accuracyOf(DayStats day) =>
      day.reviews == 0 ? null : day.accuracy;

  static List<double> _forecast(List<Flashcard> cards, DateTime today) {
    final buckets = List<double>.filled(_forecastDays, 0);
    for (final card in cards) {
      final due = card.dueAt;
      if (card.isNew || due == null) continue;
      final dueDay = DateTime(due.year, due.month, due.day);
      final index = dueDay.difference(today).inDays.clamp(0, 1 << 20);
      if (index < _forecastDays) buckets[index] += 1;
    }
    return buckets;
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    final due = deck.dueCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          DeckIconView(
            iconKey: deck.iconKey,
            color: deck.accentColor,
            size: ProgressScreen._deckIcon,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.verbatim(
                        deck.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (due > 0)
                      Text(
                        '$due due',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: status.warning),
                      ),
                  ],
                ),
                StageBarView(
                  counts: {
                    for (final stage in CardStage.values)
                      stage: deck.countStage(stage),
                  },
                  showLegend: false,
                  height: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
