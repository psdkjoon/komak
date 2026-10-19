import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/card_intake.dart';
import 'package:komak/core/deck_importer.dart';
import 'package:komak/core/import_result.dart';
import 'package:komak/core/network_importer.dart';
import 'package:komak/core/text_decoder.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/file_service.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/deck_detail_screen.dart';
import 'package:komak/ui/intake_notice.dart';
import 'package:komak/ui/widgets/page_frame.dart';

enum _ImportSource { paste, file, link }

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, this.targetDeckId});

  final String? targetDeckId;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  _ImportSource _source = _ImportSource.paste;
  ImportFormat _pasteFormat = ImportFormat.csv;
  final _pasteController = TextEditingController();
  final _urlController = TextEditingController();
  final _newDeckTitleController = TextEditingController();

  final _importer = DeckImporter();
  final _networkImporter = NetworkImporter();

  String _encoding = TextDecoder.auto;
  List<int>? _fileBytes;
  ImportFormat _fileFormat = ImportFormat.csv;
  ImportResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pasteController.dispose();
    _urlController.dispose();
    _newDeckTitleController.dispose();
    super.dispose();
  }

  void _applyResult(ImportResult result) {
    setState(() {
      _result = result;
      _errorMessage = null;
      if (result.deckTitle != null) {
        _newDeckTitleController.text = result.deckTitle!;
      }
    });
  }

  Future<void> _pickFile() async {
    final path = await FileService.pick(['json', 'csv', 'txt']);
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    if (!mounted) return;
    _fileFormat = switch (path.split('.').last.toLowerCase()) {
      'json' => ImportFormat.json,
      'csv' => ImportFormat.csv,
      _ => ImportFormat.delimitedText,
    };
    _fileBytes = bytes;
    _parseFile();
  }

  void _parseFile() {
    final bytes = _fileBytes;
    if (bytes == null) return;
    setState(() => _isLoading = true);
    try {
      final content = TextDecoder.decode(bytes, encoding: _encoding);
      _applyResult(_importer.parse(content, _fileFormat));
    } catch (error) {
      setState(
        () => _errorMessage =
            L10n.fmt('Could not read that file: {}', <Object?>[error]),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setEncoding(String value) {
    setState(() => _encoding = value);
    if (_source == _ImportSource.file) _parseFile();
  }

  void _parsePasted() {
    if (_pasteController.text.trim().isEmpty) return;
    try {
      _applyResult(_importer.parse(_pasteController.text, _pasteFormat));
    } catch (error) {
      setState(() => _errorMessage = 'Could not parse that text: $error');
    }
  }

  Future<void> _fetchFromUrl() async {
    if (_urlController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _applyResult(
        await _networkImporter.importFromUrl(
          _urlController.text.trim(),
          encoding: _encoding,
        ),
      );
    } on NetworkImportException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (error) {
      setState(() => _errorMessage = 'Something went wrong: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _commit() async {
    final result = _result;
    if (result == null || result.cards.isEmpty) return;
    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (widget.targetDeckId != null) {
      final added =
          await controller.addCardsToDeck(widget.targetDeckId!, result.cards);
      if (!mounted) return;
      showIntakeNotice(messenger, added);
      Navigator.of(context).pop();
      return;
    }

    final intake = CardIntake.prepare(const <Flashcard>[], result.cards);

    final title = _newDeckTitleController.text.trim().isEmpty
        ? 'Imported deck'.tr
        : _newDeckTitleController.text.trim();
    final deck = Deck(
      title: title,
      description: result.deckDescription ?? 'Imported deck.'.tr,
      accentColorValue: 0xFF89DCEB,
      iconKey: 'download',
      cards: intake.accepted,
    );
    await controller.addDeck(deck);
    showIntakeNotice(messenger, intake);
    if (!mounted) return;
    unawaited(
      AppRoutes.replace<void, void>(
        context,
        DeckDetailScreen(deckId: deck.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Import cards')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                SegmentedButton<_ImportSource>(
                  segments: const [
                    ButtonSegment(
                      value: _ImportSource.paste,
                      label: Text('Paste'),
                      icon: Icon(Icons.content_paste_rounded),
                    ),
                    ButtonSegment(
                      value: _ImportSource.file,
                      label: Text('File'),
                      icon: Icon(Icons.folder_open_rounded),
                    ),
                    ButtonSegment(
                      value: _ImportSource.link,
                      label: Text('Link'),
                      icon: Icon(Icons.link_rounded),
                    ),
                  ],
                  showSelectedIcon: false,
                  selected: {_source},
                  onSelectionChanged: (value) =>
                      setState(() => _source = value.first),
                ),
                switch (_source) {
                  _ImportSource.paste => _buildPasteCard(theme),
                  _ImportSource.file => _buildFileCard(theme),
                  _ImportSource.link => _buildLinkCard(theme),
                },
                if (_isLoading) const LinearProgressIndicator(),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                if (result != null) ...[
                  _FormCard(
                    children: [
                      Text(
                        '${result.cards.length} card(s) parsed',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (result.warnings.isNotEmpty)
                        Text(
                          '${result.warnings.length} line(s) skipped',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                  if (widget.targetDeckId == null)
                    TextField(
                      controller: _newDeckTitleController,
                      decoration:
                          InputDecoration(labelText: 'New deck title'.tr),
                    ),
                  FilledButton(
                    onPressed: result.cards.isEmpty ? null : _commit,
                    child: Text(
                      widget.targetDeckId == null
                          ? 'Create deck'
                          : 'Add to deck',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasteCard(ThemeData theme) {
    return _FormCard(
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final format in ImportFormat.values)
              ChoiceChip(
                label: Text(
                  switch (format) {
                    ImportFormat.json => 'JSON',
                    ImportFormat.csv => 'CSV',
                    ImportFormat.delimitedText => '=:= text',
                  },
                ),
                selected: _pasteFormat == format,
                onSelected: (_) => setState(() => _pasteFormat = format),
              ),
          ],
        ),
        TextField(
          controller: _pasteController,
          maxLines: 8,
          minLines: 6,
          style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'Paste CSV, JSON or text'.tr,
            hintMaxLines: 1,
          ),
        ),
        FilledButton(onPressed: _parsePasted, child: const Text('Parse')),
      ],
    );
  }

  Widget _buildFileCard(ThemeData theme) {
    return _FormCard(
      children: [
        Text(
          'Pick a .json, .csv or .txt file from this device.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Choose file'),
        ),
        _EncodingPicker(value: _encoding, onChanged: _setEncoding),
      ],
    );
  }

  Widget _buildLinkCard(ThemeData theme) {
    return _FormCard(
      children: [
        Text(
          "The link's Content-Type header decides how it is read.",
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com/deck.json',
          ),
        ),
        _EncodingPicker(value: _encoding, onChanged: _setEncoding),
        FilledButton(onPressed: _fetchFromUrl, child: const Text('Fetch')),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: children,
        ),
      ),
    );
  }
}

class _EncodingPicker extends StatelessWidget {
  const _EncodingPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Text encoding'.tr,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [
            for (final option in TextDecoder.options)
              DropdownMenuItem(
                value: option.id,
                child: option.id == TextDecoder.auto
                    ? Text(option.label)
                    : Text.verbatim(option.label),
              ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}
