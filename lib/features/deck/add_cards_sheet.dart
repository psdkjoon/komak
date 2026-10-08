import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_route.dart';
import 'package:komak/features/card_editor/bulk_csv_editor_screen.dart';
import 'package:komak/features/card_editor/card_editor_screen.dart';
import 'package:komak/features/import_export/import_screen.dart';

Future<void> showAddCardsSheet(BuildContext context, Deck deck) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);

      void open(Widget page) {
        Navigator.of(sheetContext).pop();
        AppRoutes.push<void>(context, page);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Add cards', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
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
