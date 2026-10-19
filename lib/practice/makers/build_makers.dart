import 'package:komak/core/text_normalizer.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/deck_profile.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/practice_masks.dart';
import 'package:komak/practice/question.dart';

const String _alphabet = 'abcdefghijklmnopqrstuvwxyz';

List<String> _letters(String word) =>
    word.trim().split('').where((String ch) => ch.trim().isNotEmpty).toList();

Question? _unscramble(
  PracticeContext c,
  Flashcard card,
  PracticeKind kind, {
  required bool answer,
}) {
  final target = answer ? card.back : card.front;
  final prompt = answer ? card.front : card.back;
  if (!isScrambleWord(target)) return null;
  final letters = _letters(target);
  if (letters.length < 3 || letters.toSet().length < 2) return null;
  return ArrangeQuestion(
    kind: kind,
    cardIds: <String>[card.id],
    prompt: prompt,
    instruction: 'Put the letters in order',
    pieces: letters,
    joiner: '',
  );
}

Question? _spell(PracticeContext c, Flashcard card) {
  if (!isScrambleWord(card.back)) return null;
  final letters = _letters(card.back);
  if (letters.length < 3) return null;
  final extras = <String>[];
  final used = letters.map((String l) => l.toLowerCase()).toSet();
  var guard = 0;
  while (extras.length < 3 && guard < 60) {
    guard += 1;
    final letter = _alphabet[c.random.nextInt(_alphabet.length)];
    if (used.contains(letter) || extras.contains(letter)) continue;
    extras.add(letter);
  }
  return ArrangeQuestion(
    kind: PracticeKind.spellFromBank,
    cardIds: <String>[card.id],
    prompt: card.front,
    instruction: 'Spell the answer. Some letters are extra.',
    pieces: letters,
    extras: extras,
    joiner: '',
  );
}

List<String> _words(String text) =>
    text.trim().split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).toList();

Question? _phrase(PracticeContext c, Flashcard card) {
  final words = _words(card.back);
  if (words.length < 3 || words.length > 9) return null;
  return ArrangeQuestion(
    kind: PracticeKind.buildPhrase,
    cardIds: <String>[card.id],
    prompt: card.front,
    instruction: 'Put the words in order',
    pieces: words,
  );
}

Question? _example(PracticeContext c, Flashcard card) {
  final example = card.example;
  if (example == null || !hasText(example)) return null;
  final words = _words(example);
  if (words.length < 3 || words.length > 12) return null;
  return ArrangeQuestion(
    kind: PracticeKind.buildExample,
    cardIds: <String>[card.id],
    prompt: card.front,
    instruction: 'Build the sentence',
    pieces: words,
    preview: Preview(lines: <String>[example], seconds: 5),
  );
}

Question? _chunks(PracticeContext c, Flashcard card) {
  if (!DeckProfile.isLongWord(card.back)) return null;
  final chunks = chunksOf(card.back.trim(), c.random);
  if (chunks.length < 3) return null;
  return ArrangeQuestion(
    kind: PracticeKind.buildChunks,
    cardIds: <String>[card.id],
    prompt: card.front,
    instruction: 'Assemble the pieces',
    pieces: chunks,
    joiner: '',
  );
}

Question? _complete(PracticeContext c, Flashcard card) {
  final word = card.back.trim();
  if (!DeckProfile.isLongWord(word)) return null;
  final chars = word.split('');
  if (chars.length < 6) return null;
  final start = 1 + c.random.nextInt(chars.length - 3);
  final chunk = chars.sublist(start, start + 2).join();
  final mask =
      '${chars.sublist(0, start).join(' ')} _ _ ${chars.sublist(start + 2).join(' ')}'
          .trim();
  final valid = c.validBackKeys(card);
  final taken = <String>{chunk.toLowerCase()};
  final options = <String>[chunk];
  String fill(String piece) =>
      chars.sublist(0, start).join() + piece + chars.sublist(start + 2).join();
  final pool = <String>[];
  for (final other in c.cards) {
    final w = other.back.trim();
    if (w.length >= 4) {
      final at = c.random.nextInt(w.length - 1);
      pool.add(w.substring(at, at + 2));
    }
  }
  pool.shuffle(c.random);
  var guard = 0;
  while (options.length < 4 && guard < 80) {
    guard += 1;
    final piece = pool.isNotEmpty
        ? pool.removeLast()
        : _alphabet[c.random.nextInt(26)] + _alphabet[c.random.nextInt(26)];
    if (piece.contains(' ') || piece.length != 2) continue;
    if (!taken.add(piece.toLowerCase())) continue;
    if (valid.contains(textKey(fill(piece)))) continue;
    options.add(piece);
  }
  if (options.length < 3) return null;
  options.shuffle(c.random);
  return buildChoice(
    kind: PracticeKind.completeWord,
    card: card,
    prompt: card.front,
    instruction: 'Complete the word',
    detail: mask,
    options: options,
    correct: chunk,
    reveal: word,
  );
}

final Map<PracticeKind, Maker> buildMakers = <PracticeKind, Maker>{
  PracticeKind.unscrambleAnswer: (PracticeContext c, Flashcard card) =>
      _unscramble(c, card, PracticeKind.unscrambleAnswer, answer: true),
  PracticeKind.unscrambleQuestion: (PracticeContext c, Flashcard card) =>
      _unscramble(c, card, PracticeKind.unscrambleQuestion, answer: false),
  PracticeKind.spellFromBank: _spell,
  PracticeKind.buildPhrase: _phrase,
  PracticeKind.buildExample: _example,
  PracticeKind.buildChunks: _chunks,
  PracticeKind.completeWord: _complete,
};
