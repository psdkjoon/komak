import 'dart:math';

import 'package:komak/core/repetition_scheduler.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/deck_profile.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_engine.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

class PracticeSession {
  PracticeSession({
    required this.deck,
    required Set<PracticeKind> wanted,
    required this.length,
    Random? random,
  })  : _random = random ?? Random(),
        context = PracticeContext(deck, random: random) {
    final profile = DeckProfile.of(deck.cards);
    kinds = wanted.where(profile.supports).toList();
    if (kinds.isEmpty && profile.supports(PracticeKind.typeAnswer)) {
      kinds = <PracticeKind>[PracticeKind.typeAnswer];
    }
    _buildPool();
  }

  static const int _batchSize = 20;
  static const int _newPerSession = 8;
  static const int _retryGap = 4;
  static const int _maxRetries = 2;

  final Deck deck;
  final int length;
  final PracticeContext context;
  final Random _random;
  final RepetitionScheduler _scheduler = RepetitionScheduler();

  List<PracticeKind> kinds = <PracticeKind>[];
  List<Flashcard> _pool = <Flashcard>[];
  final List<Flashcard> _queue = <Flashcard>[];
  final List<(int, String)> _retries = <(int, String)>[];
  final Map<String, int> _retryCounts = <String, int>{};
  final Set<String> _met = <String>{};
  final List<PracticeKind> _recent = <PracticeKind>[];
  Question? _pending;

  int asked = 0;
  int correct = 0;
  int streak = 0;
  int bestStreak = 0;
  final Map<String, Flashcard> missed = <String, Flashcard>{};

  bool get endless => length == endlessPractice;

  bool get finished => !endless && asked >= length;

  void _buildPool() {
    final seen = <Flashcard>[];
    final fresh = <Flashcard>[];
    for (final c in deck.cards) {
      if (c.isNew && c.timesShown == 0) {
        fresh.add(c);
      } else {
        seen.add(c);
      }
    }
    fresh.shuffle(_random);
    _pool = <Flashcard>[...seen, ...fresh.take(seen.isEmpty ? 12 : _newPerSession)];
    if (_pool.isEmpty) _pool = List<Flashcard>.of(deck.cards);
  }

  Flashcard _nextCard() {
    if (_queue.isEmpty) {
      final last = _lastCardId;
      final batch = _scheduler.pickSessionCards(_pool, _batchSize);
      if (batch.length > 1 && batch.first.id == last) {
        batch.add(batch.removeAt(0));
      }
      _queue.addAll(batch);
    }
    final card = _queue.removeAt(0);
    _lastCardId = card.id;
    return card;
  }

  String? _lastCardId;

  Question? next() {
    final pending = _pending;
    if (pending != null) {
      _pending = null;
      asked += 1;
      return pending;
    }
    if (finished || deck.cards.isEmpty) return null;
    final retry = _takeRetry();
    final card = retry ?? _nextCard();
    final question = _compose(card, retryMode: retry != null);
    if (question == null) return null;
    if (question.kind.needsExposure &&
        card.isNew &&
        card.timesShown == 0 &&
        _met.add(card.id)) {
      _pending = question;
      return MeetQuestion(card);
    }
    asked += 1;
    return question;
  }

  Flashcard? _takeRetry() {
    for (var i = 0; i < _retries.length; i++) {
      if (_retries[i].$1 <= asked) {
        final id = _retries.removeAt(i).$2;
        for (final c in deck.cards) {
          if (c.id == id) return c;
        }
      }
    }
    return null;
  }

  Question? _compose(Flashcard card, {required bool retryMode}) {
    var pool = kinds;
    if (retryMode) {
      final easy = kinds
          .where(
            (PracticeKind k) =>
                k.section == PracticeSection.choose ||
                k.section == PracticeSection.quick ||
                k.section == PracticeSection.connect,
          )
          .toList();
      if (easy.isNotEmpty) pool = easy;
    }
    final scored = <(double, PracticeKind)>[
      for (final k in pool)
        (
          _random.nextDouble() * 2 -
              (_recent.contains(k) ? 3 : 0) -
              (_recent.isNotEmpty && _recent.last.section == k.section ? 1 : 0),
          k,
        ),
    ]..sort(((double, PracticeKind) a, (double, PracticeKind) b) => b.$1.compareTo(a.$1));
    for (final entry in scored) {
      final q = makeQuestion(entry.$2, context, card);
      if (q != null) {
        _recent.add(entry.$2);
        if (_recent.length > 6) _recent.removeAt(0);
        return q;
      }
    }
    for (final k in <PracticeKind>[
      PracticeKind.typeAnswer,
      PracticeKind.flashForward,
    ]) {
      final q = makeQuestion(k, context, card);
      if (q != null) return q;
    }
    return null;
  }

  void record(Question question, Set<String> missedIds) {
    if (question is MeetQuestion) return;
    final ok = missedIds.isEmpty;
    if (ok) {
      correct += 1;
      streak += 1;
      bestStreak = max(bestStreak, streak);
    } else {
      streak = 0;
    }
    for (final id in missedIds) {
      for (final c in deck.cards) {
        if (c.id != id) continue;
        missed[id] = c;
        final used = _retryCounts[id] ?? 0;
        if (used < _maxRetries) {
          _retryCounts[id] = used + 1;
          _retries.add((asked + _retryGap, id));
        }
      }
    }
  }
}
