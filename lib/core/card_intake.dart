import 'package:komak/core/text_normalizer.dart';
import 'package:komak/decks/flashcard.dart';

const int maxCardsPerDeck = 1500;

String _part(String value) {
  final folded = normalizeAnswer(value);
  return folded.isEmpty ? value.trim().toLowerCase() : folded;
}

String cardKey(Flashcard card) => '${_part(card.front)}\u0000${_part(card.back)}';

class CardIntake {
  const CardIntake({
    required this.accepted,
    required this.duplicates,
    required this.overflow,
  });

  final List<Flashcard> accepted;
  final int duplicates;
  final int overflow;

  bool get changedAnything => accepted.isNotEmpty;

  static CardIntake prepare(
    Iterable<Flashcard> existing,
    Iterable<Flashcard> incoming,
  ) {
    final seen = <String>{for (final card in existing) cardKey(card)};
    var room = maxCardsPerDeck - existing.length;
    final accepted = <Flashcard>[];
    var duplicates = 0;
    var overflow = 0;
    for (final card in incoming) {
      if (!seen.add(cardKey(card))) {
        duplicates += 1;
        continue;
      }
      if (room <= 0) {
        overflow += 1;
        continue;
      }
      room -= 1;
      accepted.add(card);
    }
    return CardIntake(
      accepted: accepted,
      duplicates: duplicates,
      overflow: overflow,
    );
  }
}
