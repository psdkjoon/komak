import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/card_intake.dart';
import 'package:komak/localization/localization.dart';

String intakeMessage(CardIntake intake) {
  final parts = [
    L10n.fmt('{} cards added', [intake.accepted.length]),
    if (intake.duplicates > 0)
      L10n.fmt('{} duplicates skipped', [intake.duplicates]),
    if (intake.overflow > 0)
      L10n.fmt('{} over the {} card limit', [intake.overflow, maxCardsPerDeck]),
  ];
  return parts.join(' · ');
}

void showIntakeNotice(ScaffoldMessengerState messenger, CardIntake intake) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text.verbatim(intakeMessage(intake))));
}
