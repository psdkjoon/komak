import 'package:komak/core/models/deck.dart';
import 'package:komak/data/builtin_decks/extra_decks.dart';
import 'package:komak/data/builtin_decks/gregorian_months_deck.dart';
import 'package:komak/data/builtin_decks/world_capitals_deck.dart';

List<Deck> buildBuiltInDecks() {
  return <Deck>[
    buildMonthDaysDeck(),
    buildMonthOrderDeck(),
    buildWorldCapitalsDeck(),
    ...buildExtraBuiltInDecks(),
  ];
}

Deck? buildBuiltInDeckByKey(String key) {
  for (final Deck deck in buildBuiltInDecks()) {
    if (deck.builtInKey == key) return deck;
  }
  return null;
}
