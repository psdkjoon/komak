import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/services/import_result.dart';
import 'package:komak/core/services/import_service.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';

class BulkCsvEditorScreen extends StatefulWidget {
  const BulkCsvEditorScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<BulkCsvEditorScreen> createState() => _BulkCsvEditorScreenState();
}

class _BulkCsvEditorScreenState extends State<BulkCsvEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImportService _importService = ImportService();
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
      setState(() => _preview = _importService.parseCsv(value));
    } catch (_) {
      setState(() => _preview = null);
    }
  }

  Future<void> _addAll() async {
    final List<Flashcard>? cards = _preview?.cards;
    if (cards == null || cards.isEmpty) return;
    final AppController controller = AppScope.of(context);
    await controller.addCardsToDeck(widget.deckId, cards);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ImportResult? preview = _preview;

    return Scaffold(
      appBar: AppBar(title: const Text('Add many cards')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'One card per line: front,back — optionally ,orderIndex,groupId. A header row is optional.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                flex: 3,
                child: SectionCard(
                  expand: true,
                  padding: const EdgeInsets.all(AppSpacing.xs),
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
              const SizedBox(height: AppSpacing.md),
              if (preview != null)
                Expanded(
                  flex: 2,
                  child: SectionCard(
                    expand: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          preview.warnings.isEmpty
                              ? '${preview.cards.length} card(s) ready'
                              : '${preview.cards.length} card(s) ready, ${preview.warnings.length} skipped',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Expanded(
                          child: ListView.builder(
                            itemCount: preview.cards.length.clamp(0, 30),
                            itemBuilder: (BuildContext context, int index) {
                              final Flashcard card = preview.cards[index];
                              return Text(
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
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed:
                    preview == null || preview.cards.isEmpty ? null : _addAll,
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
    );
  }
}
