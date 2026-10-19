import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/deck.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/bulk_csv_editor_screen.dart';
import 'package:komak/ui/card_editor_screen.dart';
import 'package:komak/ui/import_screen.dart';

Future<void> showAddCardsSheet(BuildContext context, Deck deck) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      void open(Widget page) {
        Navigator.of(sheetContext).pop();
        unawaited(AppRoutes.push<void>(context, page));
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxs,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Add cards', style: theme.textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('One by one'),
                subtitle: const Text('Write a single card with the editor.'),
                onTap: () => open(CardEditorScreen(deckId: deck.id)),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Many at once (CSV)'),
                subtitle:
                    const Text('Type or paste several cards, one per line.'),
                onTap: () => open(BulkCsvEditorScreen(deckId: deck.id)),
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('From a file or link'),
                subtitle: const Text('Import JSON, CSV or =:= text.'),
                onTap: () => open(ImportScreen(targetDeckId: deck.id)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
