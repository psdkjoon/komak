import 'package:flutter/material.dart';

enum PracticeSection {
  choose(
    'Choose',
    'Pick the right answer from a few options.',
    Icons.checklist_rounded,
  ),
  type(
    'Type',
    'Write the answer yourself, with or without hints.',
    Icons.keyboard_rounded,
  ),
  connect(
    'Connect',
    'Match, sort and put things in order.',
    Icons.compare_arrows_rounded,
  ),
  build(
    'Build',
    'Assemble words and sentences from pieces.',
    Icons.extension_rounded,
  ),
  recall(
    'Recall',
    'Think first, then check yourself.',
    Icons.psychology_alt_rounded,
  ),
  quick(
    'Quick',
    'Fast true or false and timed rounds.',
    Icons.bolt_rounded,
  ),
  memory(
    'Memory',
    'Look first, then remember what you saw.',
    Icons.visibility_rounded,
  );

  const PracticeSection(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  List<PracticeKind> get kinds =>
      PracticeKind.values.where((PracticeKind k) => k.section == this).toList();
}

enum Need {
  any('Works with any card.'),
  three('Needs at least 3 cards with different answers.'),
  four('Needs at least 4 cards with different answers.'),
  six('Needs at least 6 cards with different answers.'),
  groups('Needs cards in 2 or more groups.'),
  threeGroups('Needs cards in 3 or more groups.'),
  order('Needs 3 or more cards with an order position.'),
  reading('Needs 4 or more cards with a reading.'),
  example('Needs 4 or more cards with an example.'),
  cloze('Needs examples that contain the card front.'),
  phrase('Needs answers made of several words.'),
  word('Needs single-word answers of 3 to 12 letters.'),
  frontWord('Needs single-word fronts of 3 to 12 letters.'),
  longWord('Needs single-word answers of 6 or more letters.');

  const Need(this.description);

  final String description;
}

enum PracticeKind {
  pickAnswer(PracticeSection.choose, 'Pick the answer', Icons.checklist_rounded, Need.four),
  pickQuestion(PracticeSection.choose, 'Pick the question', Icons.swap_horiz_rounded, Need.four),
  pickAnswerThree(PracticeSection.choose, 'Pick from three', Icons.looks_3_rounded, Need.three),
  pickAnswerSix(PracticeSection.choose, 'Pick from six', Icons.looks_6_rounded, Need.six),
  pickReading(PracticeSection.choose, 'Pick the reading', Icons.translate_rounded, Need.reading),
  pickByReading(PracticeSection.choose, 'Pick by reading', Icons.record_voice_over_rounded, Need.reading),
  pickGroup(PracticeSection.choose, 'Pick the group', Icons.folder_open_rounded, Need.groups),
  oddOneOut(PracticeSection.choose, 'Odd one out', Icons.search_rounded, Need.groups),
  fillBlankChoice(PracticeSection.choose, 'Fill the blank', Icons.format_quote_rounded, Need.cloze),
  pickExample(PracticeSection.choose, 'Pick the example', Icons.notes_rounded, Need.example),
  wrongPair(PracticeSection.choose, 'Spot the wrong pair', Icons.rule_rounded, Need.four),
  pickNext(PracticeSection.choose, 'What comes next', Icons.skip_next_rounded, Need.order),
  pickPrevious(PracticeSection.choose, 'What came before', Icons.skip_previous_rounded, Need.order),
  pickBetween(PracticeSection.choose, 'What fits between', Icons.vertical_align_center_rounded, Need.order),

  typeAnswer(PracticeSection.type, 'Type the answer', Icons.keyboard_rounded, Need.any, needsExposure: true),
  typeQuestion(PracticeSection.type, 'Type the question', Icons.keyboard_return_rounded, Need.any, needsExposure: true),
  typeHint(PracticeSection.type, 'Type with first letters', Icons.lightbulb_outline_rounded, Need.any, needsExposure: true),
  typeGaps(PracticeSection.type, 'Fill the missing letters', Icons.spellcheck_rounded, Need.any, needsExposure: true),
  typeVowels(PracticeSection.type, 'Add the vowels', Icons.text_fields_rounded, Need.any, needsExposure: true),
  typeCloze(PracticeSection.type, 'Type the missing word', Icons.edit_note_rounded, Need.cloze, needsExposure: true),
  typeReading(PracticeSection.type, 'Type the reading', Icons.translate_rounded, Need.reading, needsExposure: true),
  typeFromReading(PracticeSection.type, 'Type from the reading', Icons.record_voice_over_rounded, Need.reading, needsExposure: true),
  typeForgiving(PracticeSection.type, 'Forgiving typing', Icons.favorite_border_rounded, Need.any, needsExposure: true),
  typeFixTypo(PracticeSection.type, 'Fix the typo', Icons.auto_fix_high_rounded, Need.any, needsExposure: true),
  typeNext(PracticeSection.type, 'Type what comes next', Icons.arrow_forward_rounded, Need.order, needsExposure: true),
  typeGroup(PracticeSection.type, 'Type the group', Icons.label_outline_rounded, Need.groups, needsExposure: true),

  matchThree(PracticeSection.connect, 'Match three pairs', Icons.link_rounded, Need.three),
  matchFour(PracticeSection.connect, 'Match four pairs', Icons.compare_arrows_rounded, Need.four),
  matchSix(PracticeSection.connect, 'Match six pairs', Icons.hub_rounded, Need.six),
  matchReverse(PracticeSection.connect, 'Match answers to questions', Icons.swap_vert_rounded, Need.four),
  matchReadings(PracticeSection.connect, 'Match readings', Icons.translate_rounded, Need.reading),
  matchExamples(PracticeSection.connect, 'Match examples', Icons.notes_rounded, Need.example),
  sortGroups(PracticeSection.connect, 'Sort into two groups', Icons.call_split_rounded, Need.groups),
  sortThreeGroups(PracticeSection.connect, 'Sort into three groups', Icons.account_tree_rounded, Need.threeGroups),
  orderSequence(PracticeSection.connect, 'Put in order', Icons.format_list_numbered_rounded, Need.order),
  orderShort(PracticeSection.connect, 'Put three in order', Icons.sort_rounded, Need.order),

  unscrambleAnswer(PracticeSection.build, 'Unscramble the answer', Icons.shuffle_rounded, Need.word),
  unscrambleQuestion(PracticeSection.build, 'Unscramble the question', Icons.shuffle_on_rounded, Need.frontWord),
  spellFromBank(PracticeSection.build, 'Spell from letters', Icons.abc_rounded, Need.word),
  buildPhrase(PracticeSection.build, 'Build the phrase', Icons.short_text_rounded, Need.phrase),
  buildExample(PracticeSection.build, 'Build the sentence', Icons.wrap_text_rounded, Need.example),
  buildChunks(PracticeSection.build, 'Assemble the pieces', Icons.extension_rounded, Need.longWord),
  completeWord(PracticeSection.build, 'Complete the word', Icons.content_cut_rounded, Need.longWord),

  flashForward(PracticeSection.recall, 'Recall the answer', Icons.psychology_alt_rounded, Need.any, needsExposure: true),
  flashBackward(PracticeSection.recall, 'Recall the question', Icons.flip_rounded, Need.any, needsExposure: true),
  flashReading(PracticeSection.recall, 'Recall the reading', Icons.translate_rounded, Need.reading, needsExposure: true),
  flashExample(PracticeSection.recall, 'Use it in a sentence', Icons.chat_bubble_outline_rounded, Need.example, needsExposure: true),
  flashFull(PracticeSection.recall, 'Say everything you know', Icons.menu_book_rounded, Need.any, needsExposure: true),
  thinkFirst(PracticeSection.recall, 'Think for five seconds', Icons.hourglass_bottom_rounded, Need.any, needsExposure: true),

  trueFalse(PracticeSection.quick, 'True or false', Icons.fact_check_rounded, Need.three),
  trueFalseGroup(PracticeSection.quick, 'True or false: group', Icons.folder_open_rounded, Need.groups),
  trueFalseReading(PracticeSection.quick, 'True or false: reading', Icons.translate_rounded, Need.reading),
  trueFalseExample(PracticeSection.quick, 'True or false: example', Icons.notes_rounded, Need.example),
  sameGroup(PracticeSection.quick, 'Same group?', Icons.join_inner_rounded, Need.groups),
  twoChoice(PracticeSection.quick, 'Either or', Icons.alt_route_rounded, Need.three),
  sprintChoice(PracticeSection.quick, 'Sprint: pick the answer', Icons.timer_rounded, Need.four),
  sprintTrueFalse(PracticeSection.quick, 'Sprint: true or false', Icons.speed_rounded, Need.three),
  sprintReverse(PracticeSection.quick, 'Sprint: pick the question', Icons.av_timer_rounded, Need.four),
  sprintType(PracticeSection.quick, 'Sprint: type it', Icons.bolt_rounded, Need.any, needsExposure: true),

  memoryThree(PracticeSection.memory, 'Memory: three pairs', Icons.grid_view_rounded, Need.three),
  memoryFour(PracticeSection.memory, 'Memory: four pairs', Icons.view_module_rounded, Need.four),
  memoryReading(PracticeSection.memory, 'Memory: readings', Icons.translate_rounded, Need.reading),
  rememberOrder(PracticeSection.memory, 'Remember the order', Icons.reorder_rounded, Need.four),
  whichVanished(PracticeSection.memory, 'Which one vanished', Icons.visibility_off_rounded, Need.six),
  spotSeen(PracticeSection.memory, 'Spot what you saw', Icons.remove_red_eye_rounded, Need.six),
  peekThenPick(PracticeSection.memory, 'Peek, then pick', Icons.preview_rounded, Need.four),
  peekThenType(PracticeSection.memory, 'Peek, then type', Icons.edit_rounded, Need.any);

  const PracticeKind(
    this.section,
    this.label,
    this.icon,
    this.need, {
    this.needsExposure = false,
  });

  final PracticeSection section;
  final String label;
  final IconData icon;
  final Need need;
  final bool needsExposure;

  static PracticeKind? tryParse(String name) {
    for (final PracticeKind kind in PracticeKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}
