import 'package:komak/decks/flashcard.dart';
import 'package:komak/practice/makers/build_makers.dart';
import 'package:komak/practice/makers/choose_makers.dart';
import 'package:komak/practice/makers/connect_makers.dart';
import 'package:komak/practice/makers/memory_makers.dart';
import 'package:komak/practice/makers/quick_makers.dart';
import 'package:komak/practice/makers/recall_makers.dart';
import 'package:komak/practice/makers/type_makers.dart';
import 'package:komak/practice/practice_context.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/practice/question.dart';

final Map<PracticeKind, Maker> practiceMakers = <PracticeKind, Maker>{
  ...chooseMakers,
  ...typeMakers,
  ...connectMakers,
  ...buildMakers,
  ...recallMakers,
  ...quickMakers,
  ...memoryMakers,
};

bool get everyKindHasMaker => practiceMakers.length == PracticeKind.values.length;

Question? makeQuestion(
  PracticeKind kind,
  PracticeContext context,
  Flashcard card,
) {
  final maker = practiceMakers[kind];
  if (maker == null) return null;
  try {
    return maker(context, card);
  } on Object {
    return null;
  }
}
