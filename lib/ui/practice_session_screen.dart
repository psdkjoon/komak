import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/practice/practice_feedback.dart';
import 'package:komak/practice/practice_feedback_controller.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/practice_session.dart';
import 'package:komak/practice/question.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/widgets/celebration_view.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/info_pill.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/practice_feedback_view.dart';
import 'package:komak/ui/widgets/question/arrange_view.dart';
import 'package:komak/ui/widgets/question/choice_view.dart';
import 'package:komak/ui/widgets/question/flash_view.dart';
import 'package:komak/ui/widgets/question/match_view.dart';
import 'package:komak/ui/widgets/question/meet_view.dart';
import 'package:komak/ui/widgets/question/memory_view.dart';
import 'package:komak/ui/widgets/question/sort_view.dart';
import 'package:komak/ui/widgets/question/type_view.dart';

class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.deckId,
    this.kinds,
    this.section,
    this.length,
  });

  final String deckId;
  final Set<PracticeKind>? kinds;
  final PracticeSection? section;
  final int? length;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  static const double _progressHeight = 6;
  static const Offset _slideOffset = Offset(0.04, 0);
  static const Duration _autoAdvance = Duration(milliseconds: 1100);

  late final AppController _controller;
  final _feedback = PracticeFeedbackController();
  late PracticeSession _session;
  BuildContext? _scopeContext;
  Timer? _auto;
  Question? _question;
  Set<String> _missed = <String>{};
  String? _note;
  bool _resolved = false;
  bool _finished = false;
  bool _countedSession = false;
  int _answered = 0;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _controller = AppScope.read(context);
    _start(notify: false);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _feedback.dispose();
    super.dispose();
  }

  Set<PracticeKind> _kindsFor(Deck deck) {
    final explicit = widget.kinds;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final enabled = deck.enabledKinds;
    final section = widget.section;
    if (section != null) {
      final inSection = section.kinds.toSet();
      final chosen = inSection.intersection(enabled);
      return chosen.isEmpty ? inSection : chosen;
    }
    return enabled.isEmpty ? PracticeKind.values.toSet() : enabled;
  }

  void _start({bool notify = true}) {
    final deck = _controller.deckById(widget.deckId);
    _auto?.cancel();
    _session = PracticeSession(
      deck: deck,
      wanted: _kindsFor(deck),
      length: widget.length ?? deck.practiceLength,
    );
    _finished = false;
    _answered = 0;
    _advance(notify: notify);
  }

  void _advance({bool notify = true}) {
    _auto?.cancel();
    final next = _session.next();
    if (next == null) {
      if (_answered > 0) _finish();
      return;
    }
    void apply() {
      _question = next;
      _missed = <String>{};
      _note = null;
      _resolved = false;
      _seq += 1;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _finish() {
    if (_finished) return;
    unawaited(SoundService.play(AppSound.success));
    if (mounted) setState(() => _finished = true);
  }

  void _onResolved(Set<String> missed, {String? note}) {
    final question = _question;
    if (question == null || _resolved) return;
    if (question is MeetQuestion) {
      _advance();
      return;
    }
    _resolved = true;
    _session.record(question, missed);
    _answered += 1;
    final ok = missed.isEmpty;
    final needsSound = question is ChoiceQuestion ||
        question is TypeQuestion ||
        question is ArrangeQuestion;
    if (needsSound) {
      PracticeFeedback.report(_scopeContext ?? context, ok);
    }
    unawaited(
      _controller.registerCardAttempts(
        widget.deckId,
        <String, bool>{
          for (final id in question.cardIds) id: !missed.contains(id),
        },
      ),
    );
    if (!_countedSession) {
      _countedSession = true;
      unawaited(_controller.completeSession());
    }
    if (question is FlashQuestion) {
      _advance();
      return;
    }
    setState(() {
      _missed = missed;
      _note = note;
    });
    if (ok) {
      _auto = Timer(AppMotion.resolve(context, _autoAdvance), () {
        if (mounted) _advance();
      });
    }
  }

  Widget _body(Question question) {
    return switch (question) {
      final ChoiceQuestion q => ChoiceView(question: q, onResolved: _onResolved),
      final TypeQuestion q => TypeView(question: q, onResolved: _onResolved),
      final MatchQuestion q => MatchView(question: q, onResolved: _onResolved),
      final ArrangeQuestion q =>
        ArrangeView(question: q, onResolved: _onResolved),
      final SortQuestion q => SortView(question: q, onResolved: _onResolved),
      final FlashQuestion q => FlashView(question: q, onResolved: _onResolved),
      final MemoryQuestion q =>
        MemoryView(question: q, onResolved: _onResolved),
      final MeetQuestion q => MeetView(question: q, onResolved: _onResolved),
    };
  }

  @override
  Widget build(BuildContext context) {
    final deck = _controller.deckById(widget.deckId);
    final theme = Theme.of(context);
    final question = _question;

    final title = Text.verbatim(
      deck.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (question == null && !_finished) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: EmptyStateView(
          icon: Icons.quiz_outlined,
          title: 'Not enough cards yet',
          message: L10n.fmt(
            'Add a few more cards to {} to start practicing.',
            <Object?>[deck.title],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: title,
        actions: [
          if (!_finished && _answered > 0)
            TextButton(onPressed: _finish, child: const Text('Finish')),
        ],
      ),
      body: PracticeFeedbackScope(
        controller: _feedback,
        child: PracticeFeedbackView(
          controller: _feedback,
          child: Builder(
            builder: (scopeContext) {
              _scopeContext = scopeContext;
              return SafeArea(
                child: PageFrame(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: _finished
                        ? _PracticeSummary(
                            answered: _answered,
                            correct: _session.correct,
                            bestStreak: _session.bestStreak,
                            missed: _session.missed.values.toList(),
                            accent: deck.accentColor,
                            onAgain: _start,
                            onDone: () => Navigator.of(context).pop(),
                          )
                        : _buildSession(theme, deck, question!),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSession(ThemeData theme, Deck deck, Question question) {
    final isMeet = question is MeetQuestion;
    final counter = _session.endless
        ? '${_session.asked}'
        : '${_session.asked} / ${_session.length}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            Text.verbatim(
              isMeet ? '' : counter,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            InfoPill(
              icon: isMeet ? Icons.fiber_new_rounded : question.kind.icon,
              label: isMeet ? 'New card' : question.kind.label,
              color: deck.accentColor,
            ),
          ],
        ),
        if (!_session.endless)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (_session.asked / _session.length).clamp(0.0, 1.0),
              ),
              duration: AppMotion.resolve(context, AppMotion.standard),
              curve: AppMotion.emphasizedCurve,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: _progressHeight,
                  color: deck.accentColor,
                );
              },
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AnimatedSwitcher(
              duration: AppMotion.resolve(context, AppMotion.standard),
              switchInCurve: AppMotion.enterCurve,
              switchOutCurve: AppMotion.exitCurve,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: _slideOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_seq),
                child: _body(question),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.resolve(context, AppMotion.quick),
          child: _resolved && _missed.isNotEmpty
              ? _ResultBar(note: _note, onNext: _advance)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.note, required this.onNext});

  final String? note;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Expanded(
            child: Text.verbatim(
              note == null || note!.isEmpty
                  ? 'Not quite'.tr
                  : L10n.fmt('Correct answer: {}', <Object?>[note]),
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          FilledButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  const _PracticeSummary({
    required this.answered,
    required this.correct,
    required this.bestStreak,
    required this.missed,
    required this.accent,
    required this.onAgain,
    required this.onDone,
  });

  final int answered;
  final int correct;
  final int bestStreak;
  final List<Flashcard> missed;
  final Color accent;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  static const double _ringSize = 140;
  static const double _ringStroke = 10;
  static const double _greatRatio = 0.8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    final ratio = answered == 0 ? 0.0 : correct / answered;
    final great = ratio >= _greatRatio;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (great)
                  CelebrationView(
                    colors: [
                      accent,
                      status.success,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: ratio),
                  duration: AppMotion.resolve(context, Durations.extralong2),
                  curve: AppMotion.emphasizedCurve,
                  builder: (context, value, child) {
                    return SizedBox(
                      width: _ringSize,
                      height: _ringSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: _ringStroke,
                            strokeCap: StrokeCap.round,
                            color: accent,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHigh,
                          ),
                          Text.verbatim(
                            '${(value * 100).round()}%',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Column(
            spacing: AppSpacing.xxs,
            children: [
              Text(
                great ? 'Great work!' : 'Session complete',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                '$correct of $answered correct',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Best streak: $bestStreak',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (missed.isNotEmpty) ...[
            Text(
              'Worth another look',
              style: theme.textTheme.titleSmall,
            ),
            for (final card in missed)
              ListTile(
                dense: true,
                title: Text.verbatim(card.front),
                subtitle: Text.verbatim(card.back),
              ),
          ],
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAgain,
                  child: const Text('Practice again'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
