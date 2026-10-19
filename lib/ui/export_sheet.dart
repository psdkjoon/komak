import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/deck_exporter.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';

Future<void> showExportSheet(BuildContext context, Deck deck) {
  final messenger = ScaffoldMessenger.of(context);

  Future<void> export(ExportFormat format) async {
    try {
      final file = await DeckExporter().saveToDisk(deck, format);
      messenger.showSnackBar(
        SnackBar(
          content: Text.verbatim(L10n.fmt('Saved to {}', <Object?>[file.path])),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text.verbatim(
            L10n.fmt('Could not export: {}', <Object?>['$error']),
          ),
        ),
      );
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
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
              Text.verbatim(
                L10n.fmt('Export {}', <Object?>[deck.title]),
                style: theme.textTheme.titleLarge,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Saved to your documents folder, ready to import again anywhere.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.data_object_rounded),
                title: const Text('JSON'),
                subtitle: const Text('Keeps order positions and groups.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(export(ExportFormat.json));
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('CSV'),
                subtitle: const Text('Opens in any spreadsheet.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(export(ExportFormat.csv));
                },
              ),
              ListTile(
                leading: const Icon(Icons.short_text_rounded),
                title: const Text('=:= text'),
                subtitle:
                    const Text('One card per line, simplest to edit by hand.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(export(ExportFormat.delimitedText));
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
