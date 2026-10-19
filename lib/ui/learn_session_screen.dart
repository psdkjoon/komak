import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/srs.dart';
import 'package:komak/core/text_normalizer.dart';
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/practice_session_screen.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/flip_card.dart';
import 'package:komak/ui/widgets/info_pill.dart';
import 'package:komak/ui/widgets/page_frame.dart';

class _Step {
  _Step(this.card, {required this.intro});

  final Flashcard card;
  final bool intro;
}

class LearnSessionScreen extends StatefulWidget {
  const LearnSessionScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<LearnSessionScreen> createState() => _LearnSessionScreenState();
}

class _LearnSessionScreenState extends State<LearnSessionScreen> {
  static const int _maxDue = 30;
  static const int _newPerSession = 10;
  static const int _relearnGap = 3;
  static const int _introGap = 2;
  static const double _progressHeight = 6;

  late final AppController _controller;
  late final List<_Step> _queue;
  late final int _totalCards;
  final _typedController = TextEditingController();

  int _finished = 0;
  int _reviews = 0;
  int _correct = 0;
  int _learned = 0;
  bool _revealed = false;
  bool _typedMode = false;
  bool _typedCorrect = false;
  bool _streakCounted = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AppScope.read(context);
    final deck = _controller.deckById(widget.deckId);
    final due = deck.cards.where((c) => c.isDue()).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final fresh = deck.cards.where((c) => c.isNew).toList();
    if (fresh.any((c) => c.orderIndex != null)) {
      fresh.sort(
        (a, b) => (a.orderIndex ?? 1 << 30).compareTo(b.orderIndex ?? 1 << 30),
      );
    }
    final dueCards = due.take(_maxDue).toList();
    final freshCards = fresh.take(_newPerSession).toList();
    _queue = [
      for (final card in dueCards) _Step(card, intro: false),
      for (final card in freshCards) _Step(card, intro: true),
    ];
    _totalCards = _queue.length;
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  _Step get _current => _queue.first;

  void _reveal() {
    unawaited(SoundService.play(AppSound.flip));
    setState(() => _revealed = true);
  }

  void _check() {
    final correct = answersMatch(_typedController.text, _current.card.back);
    unawaited(SoundService.play(AppSound.flip));
    setState(() {
      _typedCorrect = correct;
      _revealed = true;
    });
  }

  void _insertAfter(_Step step, int gap) {
    _queue.insert(gap.clamp(0, _queue.length), step);
  }

  void _gotIt() {
    final step = _queue.removeAt(0);
    _insertAfter(_Step(step.card, intro: false), _introGap);
    setState(() {
      _revealed = false;
    });
  }

  Future<void> _rate(Rating rating) async {
    final card = _current.card;
    final wasNew = card.isNew;
    final correct = rating != Rating.again;
    unawaited(SoundService.play(correct ? AppSound.correct : AppSound.wrong));
    await _controller.reviewCard(widget.deckId, card.id, rating);
    if (!_streakCounted) {
      _streakCounted = true;
      await _controller.completeSession();
    }
    if (!mounted) return;
    _queue.removeAt(0);
    _reviews += 1;
    if (correct) _correct += 1;
    if (correct) {
      _finished += 1;
      if (wasNew) _learned += 1;
    } else {
      _insertAfter(_Step(card, intro: false), _relearnGap);
    }
    _typedController.clear();
    setState(() {
      _revealed = false;
      _typedCorrect = false;
      _done = _queue.isEmpty;
    });
    if (_done) unawaited(SoundService.play(AppSound.success));
  }

  String _interval(Flashcard card, Rating rating) {
    if (rating == Rating.again) return '< 10 min'.tr;
    final days = Srs.nextInterval(card, rating);
    if (days >= Srs.maxIntervalDays) return L10n.fmt('{} y', [1]);
    if (days >= 30) return L10n.fmt('{} mo', [(days / 30).round()]);
    return L10n.fmt('{} d', [days]);
  }

  @override
  Widget build(BuildContext context) {
    final deck = _controller.deckById(widget.deckId);
    final title = Text.verbatim(
      deck.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (_totalCards == 0) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: EmptyStateView(
          icon: Icons.check_circle_outline_rounded,
          title: 'All caught up',
          message:
              'Nothing is due today. Come back tomorrow, or practice to keep the cards fresh.',
          action: FilledButton.icon(
            onPressed: () => unawaited(
              AppRoutes.replace<void, void>(
                context,
                PracticeSessionScreen(deckId: deck.id),
              ),
            ),
            icon: const Icon(Icons.quiz_rounded),
            label: const Text('Practice'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: title,
        actions: [
          if (!_done)
            IconButton(
              tooltip: (_typedMode ? 'Typing answers' : 'Flip and rate').tr,
              onPressed: () => setState(() {
                _typedMode = !_typedMode;
                _revealed = false;
                _typedController.clear();
              }),
              icon: Icon(
                _typedMode ? Icons.keyboard_rounded : Icons.flip_rounded,
                color: _typedMode ? deck.accentColor : null,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: PageFrame(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _done ? _buildSummary(deck) : _buildStep(deck),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(Deck deck) {
    final theme = Theme.of(context);
    final step = _current;
    final card = step.card;
    final remainingNew = _queue.where((s) => s.intro).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: _progressHeight,
            value: _totalCards == 0 ? 0 : _finished / _totalCards,
            color: deck.accentColor,
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xxs,
          alignment: WrapAlignment.center,
          children: [
            InfoPill(
              icon: step.intro
                  ? Icons.fiber_new_rounded
                  : Icons.psychology_alt_rounded,
              label: step.intro ? 'New card' : 'Recall',
              color: deck.accentColor,
            ),
            InfoPill(
              icon: Icons.layers_rounded,
              label: '${_queue.length} left',
            ),
            if (remainingNew > 0 && !step.intro)
              InfoPill(
                icon: Icons.fiber_new_rounded,
                label: '$remainingNew new coming',
              ),
          ],
        ),
        Expanded(
          child: step.intro
              ? _IntroCard(card: card, accent: deck.accentColor)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: FlipCard(
                    front: card.front,
                    back: card.back,
                    reading: card.reading,
                    example: card.example,
                    note: card.note,
                    showBack: _revealed,
                    onTap: _typedMode || _revealed ? () {} : _reveal,
                    accent: deck.accentColor,
                  ),
                ),
        ),
        if (step.intro)
          FilledButton.icon(
            onPressed: _gotIt,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Got it, test me soon'),
          )
        else if (!_revealed && _typedMode)
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: TextField(
                  controller: _typedController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _check(),
                  decoration: InputDecoration(
                    labelText: 'Type the answer'.tr,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _check,
                child: const Text('Check'),
              ),
            ],
          )
        else if (!_revealed)
          FilledButton.tonalIcon(
            onPressed: _reveal,
            icon: const Icon(Icons.flip_rounded),
            label: const Text('Show answer'),
          )
        else
          Column(
            spacing: AppSpacing.sm,
            children: [
              if (_typedMode)
                Text(
                  _typedCorrect ? 'Correct' : 'Not quite',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _typedCorrect
                        ? theme.extension<StatusColors>()!.success
                        : theme.colorScheme.error,
                  ),
                ),
              _RatingRow(
                card: card,
                intervalOf: _interval,
                suggested: !_typedMode
                    ? null
                    : _typedCorrect
                        ? Rating.good
                        : Rating.again,
                onRate: (rating) => unawaited(_rate(rating)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSummary(Deck deck) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    final percent = _reviews == 0 ? 0 : (_correct * 100 / _reviews).round();
    final tomorrow = DateTime.now().add(const Duration(days: 2));
    final cutoff = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final dueTomorrow = deck.cards
        .where((c) => !c.isNew && c.dueAt != null && c.dueAt!.isBefore(cutoff))
        .length;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.lg,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: _summaryIcon,
              color: status.streak,
            ),
            Text('Session complete', style: theme.textTheme.headlineSmall),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                InfoPill(
                  icon: Icons.check_rounded,
                  label: '$_reviews reviews',
                  color: deck.accentColor,
                ),
                InfoPill(
                  icon: Icons.fiber_new_rounded,
                  label: '$_learned new cards learned',
                  color: status.info,
                ),
                InfoPill(
                  icon: Icons.percent_rounded,
                  label: '$percent% remembered',
                  color: status.success,
                ),
                InfoPill(
                  icon: Icons.event_rounded,
                  label: '$dueTomorrow due by tomorrow',
                  color: status.warning,
                ),
              ],
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
            TextButton(
              onPressed: () => unawaited(
                AppRoutes.replace<void, void>(
                  context,
                  PracticeSessionScreen(deckId: deck.id),
                ),
              ),
              child: const Text('Practice this deck'),
            ),
          ],
        ),
      ),
    );
  }

  static const double _summaryIcon = 64;
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.card,
    required this.intervalOf,
    required this.suggested,
    required this.onRate,
  });

  final Flashcard card;
  final String Function(Flashcard card, Rating rating) intervalOf;
  final Rating? suggested;
  final ValueChanged<Rating> onRate;

  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    final options = [
      (Rating.again, 'Again', theme.colorScheme.error),
      (Rating.hard, 'Hard', status.warning),
      (Rating.good, 'Good', status.success),
      (Rating.easy, 'Easy', status.info),
    ];

    return Row(
      spacing: AppSpacing.xxs,
      children: [
        for (final (rating, label, color) in options)
          Expanded(
            child: FilledButton(
              onPressed: () => onRate(rating),
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.16),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.sm,
                ),
                side: suggested == rating
                    ? BorderSide(color: color, width: _borderWidth)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.labelLarge),
                  Text.verbatim(
                    intervalOf(card, rating),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.card, required this.accent});

  final Flashcard card;
  final Color accent;

  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget section(String label, String value, TextStyle? style) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xxs,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text.verbatim(value, style: style),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: accent.withValues(alpha: 0.5),
          width: _borderWidth,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.18), scheme.surfaceContainer],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.lg,
          children: [
            section('Name', card.front, theme.textTheme.headlineMedium),
            if ((card.reading ?? '').isNotEmpty)
              section(
                'Reading',
                card.reading!,
                theme.textTheme.titleMedium?.copyWith(color: accent),
              ),
            section('Meaning', card.back, theme.textTheme.titleLarge),
            if ((card.example ?? '').isNotEmpty)
              section(
                'Example',
                card.example!,
                theme.textTheme.bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            if ((card.note ?? '').isNotEmpty)
              section('Memory trick', card.note!, theme.textTheme.bodyMedium),
            if ((card.groupId ?? '').isNotEmpty)
              section('Group', card.groupId!, theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
