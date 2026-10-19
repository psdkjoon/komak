import 'dart:math';

import 'package:komak/practice/deck_profile.dart';

final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

const String _vowels = 'aeiouAEIOUàáâãäåèéêëìíîïòóôõöùúûüÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜ';
const String _alphabet = 'abcdefghijklmnopqrstuvwxyz';

String _joinWords(List<String> words) => words.join('   ');

String? gapMask(String answer, Random random) {
  final words = answer.trim().split(RegExp(r'\s+'));
  var letters = 0;
  var hidden = 0;
  final out = <String>[];
  for (final word in words) {
    final chars = word.split('');
    final shown = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (!_letterOrDigit.hasMatch(chars[i])) {
        shown.add(chars[i]);
        continue;
      }
      letters += 1;
      if (i == 0 || random.nextDouble() < 0.4) {
        shown.add(chars[i]);
      } else {
        shown.add('_');
        hidden += 1;
      }
    }
    out.add(shown.join(' '));
  }
  if (letters < 4 || hidden < 2) return null;
  return _joinWords(out);
}

String? vowelMask(String answer) {
  final words = answer.trim().split(RegExp(r'\s+'));
  var letters = 0;
  var hidden = 0;
  final out = <String>[];
  for (final word in words) {
    final shown = <String>[];
    for (final char in word.split('')) {
      if (_letterOrDigit.hasMatch(char)) letters += 1;
      if (_vowels.contains(char)) {
        shown.add('_');
        hidden += 1;
      } else {
        shown.add(char);
      }
    }
    out.add(shown.join(' '));
  }
  if (letters < 3 || hidden < 1) return null;
  return _joinWords(out);
}

String? typoOf(String answer, Random random) {
  final chars = answer.split('');
  final swappable = <int>[];
  for (var i = 1; i < chars.length - 1; i++) {
    if (_letterOrDigit.hasMatch(chars[i]) &&
        _letterOrDigit.hasMatch(chars[i + 1]) &&
        chars[i].toLowerCase() != chars[i + 1].toLowerCase()) {
      swappable.add(i);
    }
  }
  if (swappable.isNotEmpty) {
    final at = swappable[random.nextInt(swappable.length)];
    final swapped = List<String>.of(chars);
    swapped[at] = chars[at + 1];
    swapped[at + 1] = chars[at];
    return swapped.join();
  }
  final replaceable = <int>[
    for (var i = 1; i < chars.length; i++)
      if (_alphabet.contains(chars[i].toLowerCase())) i,
  ];
  if (replaceable.isEmpty) return null;
  final at = replaceable[random.nextInt(replaceable.length)];
  var letter = _alphabet[random.nextInt(_alphabet.length)];
  while (letter == chars[at].toLowerCase()) {
    letter = _alphabet[random.nextInt(_alphabet.length)];
  }
  final replaced = List<String>.of(chars);
  replaced[at] = letter;
  return replaced.join();
}

List<String> chunksOf(String word, Random random) {
  final chars = word.split('');
  final chunks = <String>[];
  var at = 0;
  while (at < chars.length) {
    final size = 2 + random.nextInt(2);
    final end = min(at + size, chars.length);
    chunks.add(chars.sublist(at, end).join());
    at = end;
  }
  if (chunks.length > 1 && chunks.last.length == 1) {
    final tail = chunks.removeLast();
    chunks[chunks.length - 1] = '${chunks.last}$tail';
  }
  return chunks;
}

String? blankSentence(String example, String front) {
  final pattern = DeckProfile.clozePattern(front);
  if (pattern == null || !pattern.hasMatch(example)) return null;
  return example.replaceFirst(pattern, '_____');
}
