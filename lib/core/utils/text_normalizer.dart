const Map<String, String> _foldMap = <String, String>{
  'àáâãäåāăą': 'a',
  'çćčĉċ': 'c',
  'ďđ': 'd',
  'èéêëēĕėęě': 'e',
  'ĝğġģ': 'g',
  'ĥħ': 'h',
  'ìíîïĩīĭįı': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺļľŀł': 'l',
  'ñńņňŉ': 'n',
  'òóôõöøōŏő': 'o',
  'ŕŗř': 'r',
  'śŝşšș': 's',
  'ţťŧț': 't',
  'ùúûüũūŭůűų': 'u',
  'ŵ': 'w',
  'ýÿŷ': 'y',
  'źżž': 'z',
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
};

final Map<String, String> _foldLookup = <String, String>{
  for (final MapEntry<String, String> entry in _foldMap.entries)
    for (final String rune in entry.key.split('')) rune: entry.value,
};

final RegExp _punctuation = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
final RegExp _whitespace = RegExp(r'\s+');

String normalizeAnswer(String value) {
  final StringBuffer buffer = StringBuffer();
  for (final String rune in value.toLowerCase().split('')) {
    buffer.write(_foldLookup[rune] ?? rune);
  }
  return buffer
      .toString()
      .replaceAll(_punctuation, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();
}

List<String> answerAlternatives(String answer) {
  final List<String> parts = answer
      .split(RegExp(r'\s+/\s+|;'))
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? <String>[answer] : parts;
}

bool answersMatch(String input, String expected) {
  final String normalizedInput = normalizeAnswer(input);
  if (normalizedInput.isEmpty) return false;
  if (normalizedInput == normalizeAnswer(expected)) return true;
  return answerAlternatives(expected)
      .any((String alt) => normalizeAnswer(alt) == normalizedInput);
}

bool isScrambleWord(String answer) {
  final String normalized = normalizeAnswer(answer);
  return normalized.length >= 3 &&
      normalized.length <= 12 &&
      !normalized.contains(' ');
}

final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

String buildAnswerHint(String answer) {
  final List<String> words = answer.trim().split(RegExp(r'\s+'));
  return words.map((String word) {
    final List<String> chars = word.split('');
    return <String>[
      for (int i = 0; i < chars.length; i++)
        (i == 0 || !_letterOrDigit.hasMatch(chars[i])) ? chars[i] : '_',
    ].join(' ');
  }).join('   ');
}
