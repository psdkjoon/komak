import 'dart:math';

import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/models/questions/hint_typing_question.dart';
import 'package:komak/core/models/questions/matching_question.dart';
import 'package:komak/core/models/questions/memory_question.dart';
import 'package:komak/core/models/questions/multiple_choice_question.dart';
import 'package:komak/core/models/questions/odd_one_out_question.dart';
import 'package:komak/core/models/questions/order_question.dart';
import 'package:komak/core/models/questions/reverse_choice_question.dart';
import 'package:komak/core/models/questions/scramble_question.dart';
import 'package:komak/core/models/questions/self_check_question.dart';
import 'package:komak/core/models/questions/study_question.dart';
import 'package:komak/core/models/questions/text_field_question.dart';
import 'package:komak/core/models/questions/timed_question.dart';
import 'package:komak/core/models/questions/true_false_question.dart';
import 'package:komak/core/services/repetition_service.dart';
import 'package:komak/core/utils/text_normalizer.dart';

class QuestionGenerator {
  QuestionGenerator({RepetitionService? repetitionService})
      : _repetitionService = repetitionService ?? RepetitionService();

  final RepetitionService _repetitionService;
  final Random _random = Random();

  List<StudyQuestion> buildSession(Deck deck, {int? length}) {
    if (deck.cards.isEmpty) return <StudyQuestion>[];
    final int target = length ?? deck.practiceLength;
    final List<QuestionType> available = deck.playableTypes;
    if (available.isEmpty) available.add(QuestionType.textField);

    final List<Flashcard> ordered = <Flashcard>[];
    while (ordered.length < target) {
      final List<Flashcard> pass = _repetitionService.pickSessionCards(
        deck.cards,
        target - ordered.length,
      );
      if (pass.isEmpty) break;
      if (ordered.isNotEmpty &&
          pass.length > 1 &&
          pass.first.id == ordered.last.id) {
        pass.add(pass.removeAt(0));
      }
      ordered.addAll(pass);
    }

    QuestionType? previous;
    final List<StudyQuestion> questions = <StudyQuestion>[];
    for (final Flashcard card in ordered) {
      List<QuestionType> candidates = available
          .where(
            (QuestionType t) =>
                _suits(t, card, deck) &&
                (available.length == 1 || t != previous),
          )
          .toList();
      if (candidates.isEmpty) {
        candidates =
            available.where((QuestionType t) => _suits(t, card, deck)).toList();
      }
      final QuestionType type = candidates.isEmpty
          ? QuestionType.textField
          : candidates[_random.nextInt(candidates.length)];
      questions.add(_buildQuestion(type, card, deck));
      previous = type;
    }
    return questions;
  }

  bool _suits(QuestionType type, Flashcard card, Deck deck) {
    switch (type) {
      case QuestionType.scramble:
        return isScrambleWord(card.back);
      case QuestionType.hintTyping:
        return normalizeAnswer(card.back).length >= 3;
      case QuestionType.reverseChoice:
        return deck.hasUniqueBack(card);
      case QuestionType.trueFalse:
        return deck.cards.any((Flashcard c) => c.back != card.back);
      default:
        return true;
    }
  }

  StudyQuestion _buildQuestion(QuestionType type, Flashcard card, Deck deck) {
    switch (type) {
      case QuestionType.textField:
        return TextFieldQuestion(card: card);
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(card, deck);
      case QuestionType.timed:
        final MultipleChoiceQuestion base = _buildMultipleChoice(card, deck);
        return TimedQuestion(
          card: base.card,
          options: base.options,
          correctIndex: base.correctIndex,
          durationSeconds: 8,
        );
      case QuestionType.order:
        return _buildOrder(deck);
      case QuestionType.matching:
        return _buildMatching(card, deck);
      case QuestionType.oddOneOut:
        return _buildOddOneOut(card, deck);
      case QuestionType.trueFalse:
        return _buildTrueFalse(card, deck);
      case QuestionType.reverseChoice:
        return _buildReverseChoice(card, deck);
      case QuestionType.scramble:
        return _buildScramble(card);
      case QuestionType.hintTyping:
        return HintTypingQuestion(card: card, hint: buildAnswerHint(card.back));
      case QuestionType.selfCheck:
        return SelfCheckQuestion(card: card);
      case QuestionType.memory:
        return MemoryQuestion(pairs: _buildMatching(card, deck).pairs);
    }
  }

  TrueFalseQuestion _buildTrueFalse(Flashcard card, Deck deck) {
    final List<Flashcard> others = deck.cards
        .where((Flashcard c) => c.back != card.back)
        .toList()
      ..shuffle(_random);
    final String? group = card.groupId;
    final List<Flashcard> sameGroup = group == null
        ? <Flashcard>[]
        : others.where((Flashcard c) => c.groupId == group).toList();
    final bool isTrue = others.isEmpty || _random.nextBool();
    final String shown = isTrue
        ? card.back
        : (sameGroup.isNotEmpty ? sameGroup.first.back : others.first.back);
    return TrueFalseQuestion(card: card, shownAnswer: shown, isTrue: isTrue);
  }

  ReverseChoiceQuestion _buildReverseChoice(Flashcard card, Deck deck) {
    final List<Flashcard> others = deck.cards
        .where(
          (Flashcard c) =>
              c.id != card.id && c.front != card.front && deck.hasUniqueBack(c),
        )
        .toList()
      ..shuffle(_random);
    final List<String> distractors = <String>[];
    for (final Flashcard candidate in others) {
      if (distractors.length == 3) break;
      if (!distractors.contains(candidate.front)) {
        distractors.add(candidate.front);
      }
    }
    final List<String> options = <String>[card.front, ...distractors]
      ..shuffle(_random);
    return ReverseChoiceQuestion(
      card: card,
      options: options,
      correctIndex: options.indexOf(card.front),
    );
  }

  ScrambleQuestion _buildScramble(Flashcard card) {
    final String target = normalizeAnswer(card.back);
    final List<String> letters = target.split('');
    for (int attempt = 0; attempt < 12; attempt++) {
      letters.shuffle(_random);
      if (letters.join() != target) break;
    }
    return ScrambleQuestion(card: card, target: target, letters: letters);
  }

  MultipleChoiceQuestion _buildMultipleChoice(Flashcard card, Deck deck) {
    final List<Flashcard> others = deck.cards
        .where((Flashcard c) => c.id != card.id && c.back != card.back)
        .toList()
      ..shuffle(_random);
    final String? group = card.groupId;
    final List<Flashcard> sameGroup = group == null
        ? <Flashcard>[]
        : others.where((Flashcard c) => c.groupId == group).toList();
    final List<Flashcard> rest =
        others.where((Flashcard c) => !sameGroup.contains(c)).toList();

    final List<String> distractors = <String>[];
    for (final Flashcard candidate in <Flashcard>[...sameGroup, ...rest]) {
      if (distractors.length == 3) break;
      if (!distractors.contains(candidate.back)) {
        distractors.add(candidate.back);
      }
    }

    final List<String> options = <String>[card.back, ...distractors]
      ..shuffle(_random);
    return MultipleChoiceQuestion(
      card: card,
      options: options,
      correctIndex: options.indexOf(card.back),
    );
  }

  OrderQuestion _buildOrder(Deck deck) {
    final List<Flashcard> ordered = deck.cards
        .where((Flashcard c) => c.orderIndex != null)
        .toList()
      ..sort(
        (Flashcard a, Flashcard b) => a.orderIndex!.compareTo(b.orderIndex!),
      );

    final int windowSize = min(ordered.length, 6);
    final int startMax = ordered.length - windowSize;
    final int start = startMax == 0 ? 0 : _random.nextInt(startMax + 1);
    final List<Flashcard> segment = ordered.sublist(start, start + windowSize);
    final List<Flashcard> shuffled = List<Flashcard>.from(segment)
      ..shuffle(_random);

    return OrderQuestion(
      title: deck.title,
      shuffledItems: shuffled,
      correctOrderIds: segment.map((Flashcard c) => c.id).toList(),
    );
  }

  MatchingQuestion _buildMatching(Flashcard seed, Deck deck) {
    final List<Flashcard> pool = deck.cards
        .where((Flashcard c) => c.id != seed.id && c.back != seed.back)
        .toList()
      ..shuffle(_random);
    final List<Flashcard> pairs = <Flashcard>[seed];
    for (final Flashcard candidate in pool) {
      if (pairs.length == 4) break;
      if (!pairs.any((Flashcard c) => c.back == candidate.back)) {
        pairs.add(candidate);
      }
    }
    pairs.shuffle(_random);
    return MatchingQuestion(pairs: pairs);
  }

  OddOneOutQuestion _buildOddOneOut(Flashcard seed, Deck deck) {
    final String groupId = seed.groupId ?? '';
    final List<Flashcard> sameGroup = deck.cards
        .where((Flashcard c) => c.groupId == groupId && c.id != seed.id)
        .toList()
      ..shuffle(_random);
    final List<Flashcard> otherGroup = deck.cards
        .where((Flashcard c) => c.groupId != groupId)
        .toList()
      ..shuffle(_random);

    final List<Flashcard> options = <Flashcard>[seed, ...sameGroup.take(2)];
    final Flashcard imposter = otherGroup.isNotEmpty ? otherGroup.first : seed;
    if (otherGroup.isNotEmpty) options.add(imposter);
    options.shuffle(_random);

    return OddOneOutQuestion(
      options: options,
      imposterId: imposter.id,
      sharedGroupLabel: groupId.isEmpty ? 'this group' : groupId,
    );
  }
}
