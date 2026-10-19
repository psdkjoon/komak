import 'package:komak/decks/flashcard.dart';

class ImportResult {
  ImportResult({
    required this.cards,
    this.deckTitle,
    this.deckDescription,
    List<String>? warnings,
  }) : warnings = warnings ?? <String>[];

  final List<Flashcard> cards;
  final String? deckTitle;
  final String? deckDescription;
  final List<String> warnings;

  bool get isEmpty => cards.isEmpty;
}
