import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/deck_importer.dart';
import 'package:komak/core/import_result.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/intake_notice.dart';
import 'package:komak/ui/widgets/page_frame.dart';

class BulkCsvEditorScreen extends StatefulWidget {
  const BulkCsvEditorScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<BulkCsvEditorScreen> createState() => _BulkCsvEditorScreenState();
}

class _BulkCsvEditorScreenState extends State<BulkCsvEditorScreen> {
  static const int _maxPreview = 30;

  final _textController = TextEditingController();
  final _importer = DeckImporter();
  ImportResult? _preview;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updatePreview(String value) {
    if (value.trim().isEmpty) {
      setState(() => _preview = null);
      return;
    }
    try {
      setState(() => _preview = _importer.parseCsv(value));
    } catch (_) {
      setState(() => _preview = null);
    }
  }

  Future<void> _addAll() async {
    final cards = _preview?.cards;
    if (cards == null || cards.isEmpty) return;
    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final intake = await controller.addCardsToDeck(widget.deckId, cards);
    showIntakeNotice(messenger, intake);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: const Text('Add many cards')),
      body: SafeArea(
        child: PageFrame(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  'One card per line: front,back. A header row lets you add reading, example, note, order and group columns.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: TextField(
                        controller: _textController,
                        onChanged: _updatePreview,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Capital of France,Paris\nCapital of Japan,Tokyo',
                        ),
                      ),
                    ),
                  ),
                ),
                if (preview != null)
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpacing.sm,
                          children: [
                            Text(
                              preview.warnings.isEmpty
                                  ? '${preview.cards.length} card(s) ready'
                                  : '${preview.cards.length} card(s) ready, ${preview.warnings.length} skipped',
                              style: theme.textTheme.titleSmall,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount:
                                    preview.cards.length.clamp(0, _maxPreview),
                                itemBuilder: (context, index) {
                                  final card = preview.cards[index];
                                  return Text.verbatim(
                                    '${card.front} → ${card.back}',
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: preview == null || preview.cards.isEmpty
                      ? null
                      : () => unawaited(_addAll()),
                  child: Text(
                    preview == null
                        ? 'Add all cards'
                        : 'Add ${preview.cards.length} cards',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
