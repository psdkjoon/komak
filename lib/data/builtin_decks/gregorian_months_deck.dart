import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/question_type.dart';

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<int> _monthDays = <int>[
  31,
  28,
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31,
];

Deck buildMonthDaysDeck() {
  final List<Flashcard> cards = <Flashcard>[
    for (int i = 0; i < _monthNames.length; i++)
      Flashcard(
        front: _monthNames[i],
        back: _monthDays[i] == 28 ? '28 or 29 days' : '${_monthDays[i]} days',
        groupId: '${_monthDays[i]} days',
      ),
  ];

  return Deck(
    title: 'Days In Each Month',
    description: 'How many days each month of the Gregorian calendar holds.',
    accentColorValue: 0xFF89B4FA,
    iconKey: 'calendar',
    cards: cards,
    enabledTypes: <QuestionType>{
      QuestionType.multipleChoice,
      QuestionType.textField,
      QuestionType.oddOneOut,
      QuestionType.trueFalse,
      QuestionType.selfCheck,
    },
    builtInKey: 'month-days',
    practiceLength: 12,
  );
}

Deck buildMonthOrderDeck() {
  final List<Flashcard> cards = <Flashcard>[
    for (int i = 0; i < _monthNames.length; i++)
      Flashcard(
        front: _monthNames[i],
        back: '${i + 1}',
        orderIndex: i + 1,
      ),
  ];

  return Deck(
    title: 'Order Of The Months',
    description: 'Which position each month takes in the year, from 1 to 12.',
    accentColorValue: 0xFFA6E3A1,
    iconKey: 'calendar',
    cards: cards,
    enabledTypes: <QuestionType>{
      QuestionType.order,
      QuestionType.multipleChoice,
      QuestionType.textField,
      QuestionType.matching,
      QuestionType.reverseChoice,
      QuestionType.trueFalse,
      QuestionType.memory,
    },
    builtInKey: 'month-order',
    practiceLength: 12,
  );
}
