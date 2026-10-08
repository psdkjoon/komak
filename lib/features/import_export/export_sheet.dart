import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/services/export_service.dart';
import 'package:komak/core/theme/app_spacing.dart';

Future<void> showExportSheet(BuildContext context, Deck deck) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  Future<void> export(ExportFormat format) async {
    try {
      final file = await ExportService().saveToDisk(deck, format);
      messenger.showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } catch (error) {
      messenger
          .showSnackBar(SnackBar(content: Text('Could not export: $error')));
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);
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
              Text('Export ${deck.title}', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Saved to your documents folder, ready to import again anywhere.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.data_object_rounded),
                title: const Text('JSON'),
                subtitle: const Text('Keeps order positions and groups.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  export(ExportFormat.json);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('CSV'),
                subtitle: const Text('Opens in any spreadsheet.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  export(ExportFormat.csv);
                },
              ),
              ListTile(
                leading: const Icon(Icons.short_text_rounded),
                title: const Text('=:= text'),
                subtitle:
                    const Text('One card per line, simplest to edit by hand.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  export(ExportFormat.delimitedText);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
