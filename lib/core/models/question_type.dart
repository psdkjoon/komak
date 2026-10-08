import 'package:flutter/material.dart';

enum QuestionType {
  multipleChoice,
  timed,
  textField,
  order,
  matching,
  oddOneOut,
  trueFalse,
  reverseChoice,
  scramble,
  hintTyping,
  selfCheck,
  memory;

  String get label {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.timed:
        return 'Timed Recall';
      case QuestionType.textField:
        return 'Type The Answer';
      case QuestionType.order:
        return 'Correct Order';
      case QuestionType.matching:
        return 'Match The Pairs';
      case QuestionType.oddOneOut:
        return 'Odd One Out';
      case QuestionType.trueFalse:
        return 'True Or False';
      case QuestionType.reverseChoice:
        return 'Reverse Choice';
      case QuestionType.scramble:
        return 'Unscramble';
      case QuestionType.hintTyping:
        return 'Type With Hint';
      case QuestionType.selfCheck:
        return 'Self Check';
      case QuestionType.memory:
        return 'Memory Game';
    }
  }

  String get description {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Pick the right answer among a few options.';
      case QuestionType.timed:
        return 'Answer before the clock runs out.';
      case QuestionType.textField:
        return 'Type the answer from memory.';
      case QuestionType.order:
        return 'Arrange the pieces in the correct order.';
      case QuestionType.matching:
        return 'Connect each item on the left to its pair on the right.';
      case QuestionType.oddOneOut:
        return 'Spot the one option that does not belong.';
      case QuestionType.trueFalse:
        return 'Decide if the shown answer belongs to the card.';
      case QuestionType.reverseChoice:
        return 'See the answer and pick the card it belongs to.';
      case QuestionType.scramble:
        return 'Put the scrambled letters back in order.';
      case QuestionType.hintTyping:
        return 'Type the answer with the first letters as a hint.';
      case QuestionType.selfCheck:
        return 'Recall it, reveal the answer, then rate yourself.';
      case QuestionType.memory:
        return 'Flip tiles and find the matching pairs.';
    }
  }

  String get requirement {
    switch (this) {
      case QuestionType.multipleChoice:
      case QuestionType.timed:
        return 'Needs at least 4 cards.';
      case QuestionType.textField:
        return 'Works with any card.';
      case QuestionType.order:
        return 'Needs 3 or more cards with an order position.';
      case QuestionType.matching:
        return 'Needs at least 4 cards.';
      case QuestionType.oddOneOut:
        return 'Needs 4 or more cards spread over 2 or more groups.';
      case QuestionType.trueFalse:
        return 'Needs at least 3 cards with different answers.';
      case QuestionType.reverseChoice:
        return 'Needs at least 4 cards with unique answers.';
      case QuestionType.scramble:
        return 'Needs cards with a single-word answer of 3 to 12 letters.';
      case QuestionType.hintTyping:
        return 'Works with any card.';
      case QuestionType.selfCheck:
        return 'Works with any card.';
      case QuestionType.memory:
        return 'Needs at least 4 cards with different answers.';
    }
  }

  IconData get icon {
    switch (this) {
      case QuestionType.multipleChoice:
        return Icons.checklist_rounded;
      case QuestionType.timed:
        return Icons.timer_rounded;
      case QuestionType.textField:
        return Icons.keyboard_rounded;
      case QuestionType.order:
        return Icons.format_list_numbered_rounded;
      case QuestionType.matching:
        return Icons.compare_arrows_rounded;
      case QuestionType.oddOneOut:
        return Icons.search_rounded;
      case QuestionType.trueFalse:
        return Icons.rule_rounded;
      case QuestionType.reverseChoice:
        return Icons.swap_horiz_rounded;
      case QuestionType.scramble:
        return Icons.shuffle_rounded;
      case QuestionType.hintTyping:
        return Icons.lightbulb_outline_rounded;
      case QuestionType.selfCheck:
        return Icons.psychology_alt_rounded;
      case QuestionType.memory:
        return Icons.grid_view_rounded;
    }
  }

  static QuestionType? tryParse(String name) {
    for (final QuestionType type in QuestionType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}
