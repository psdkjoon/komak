import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/services/import_result.dart';
import 'package:komak/core/services/import_service.dart';
import 'package:komak/core/services/network_import_service.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_route.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/sliver_content.dart';
import 'package:komak/features/deck/deck_detail_screen.dart';

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
  final TextEditingController _pasteController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _newDeckTitleController = TextEditingController();

  final ImportService _importService = ImportService();
  final NetworkImportService _networkImportService = NetworkImportService();

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
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json', 'csv', 'txt'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final PlatformFile file = picked.files.first;
    final String? extension = file.extension?.toLowerCase();
    final ImportFormat format = switch (extension) {
      'json' => ImportFormat.json,
      'csv' => ImportFormat.csv,
      _ => ImportFormat.delimitedText,
    };

    setState(() => _isLoading = true);
    try {
      final String content = String.fromCharCodes(file.bytes ?? <int>[]);
      _applyResult(_importService.parse(content, format));
    } catch (error) {
      setState(() => _errorMessage = 'Could not read that file: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parsePasted() {
    if (_pasteController.text.trim().isEmpty) return;
    try {
      _applyResult(_importService.parse(_pasteController.text, _pasteFormat));
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
      _applyResult(await _networkImportService
          .importFromUrl(_urlController.text.trim()),);
    } on NetworkImportException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (error) {
      setState(() => _errorMessage = 'Something went wrong: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _commit() async {
    final ImportResult? result = _result;
    if (result == null || result.cards.isEmpty) return;
    final AppController controller = AppScope.of(context);

    if (widget.targetDeckId != null) {
      await controller.addCardsToDeck(widget.targetDeckId!, result.cards);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final String title = _newDeckTitleController.text.trim().isEmpty
        ? 'Imported deck'
        : _newDeckTitleController.text.trim();
    final Deck deck = Deck(
      title: title,
      description: result.deckDescription ?? 'Imported deck.',
      accentColorValue: 0xFF89DCEB,
      iconKey: 'download',
      cards: result.cards,
    );
    await controller.addDeck(deck);
    if (!mounted) return;
    unawaited(AppRoutes.replace<void, void>(
        context, DeckDetailScreen(deckId: deck.id),),);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import cards')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverContent(
              maxWidth: AppLayout.readableMaxWidth,
              sliver: SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    SegmentedButton<_ImportSource>(
                      segments: const <ButtonSegment<_ImportSource>>[
                        ButtonSegment<_ImportSource>(
                            value: _ImportSource.paste,
                            label: Text('Paste'),
                            icon: Icon(Icons.content_paste_rounded),),
                        ButtonSegment<_ImportSource>(
                            value: _ImportSource.file,
                            label: Text('File'),
                            icon: Icon(Icons.folder_open_rounded),),
                        ButtonSegment<_ImportSource>(
                            value: _ImportSource.link,
                            label: Text('Link'),
                            icon: Icon(Icons.link_rounded),),
                      ],
                      showSelectedIcon: false,
                      selected: <_ImportSource>{_source},
                      onSelectionChanged: (Set<_ImportSource> value) =>
                          setState(() => _source = value.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_source == _ImportSource.paste)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Wrap(
                              spacing: AppSpacing.xs,
                              children: ImportFormat.values
                                  .map((ImportFormat format) {
                                return ChoiceChip(
                                  label: Text(
                                    switch (format) {
                                      ImportFormat.json => 'JSON',
                                      ImportFormat.csv => 'CSV',
                                      ImportFormat.delimitedText => '=:= text',
                                    },
                                  ),
                                  selected: _pasteFormat == format,
                                  onSelected: (_) =>
                                      setState(() => _pasteFormat = format),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _pasteController,
                              maxLines: 8,
                              minLines: 6,
                              style: const TextStyle(fontFamily: 'monospace'),
                              decoration: const InputDecoration(
                                  hintText: 'Paste CSV, JSON or text',
                                  hintMaxLines: 1,),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton(
                                onPressed: _parsePasted,
                                child: const Text('Parse'),),
                          ],
                        ),
                      )
                    else if (_source == _ImportSource.file)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Pick a .json, .csv or .txt file from this device.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text('Choose file'),
                            ),
                          ],
                        ),
                      )
                    else
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "The link's Content-Type header decides how it is read.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                  hintText: 'https://example.com/deck.json',),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton(
                                onPressed: _fetchFromUrl,
                                child: const Text('Fetch'),),
                          ],
                        ),
                      ),
                    if (_isLoading)
                      const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.lg),
                          child: LinearProgressIndicator(),),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(_errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),),
                      ),
                    if (_result != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${_result!.cards.length} card(s) parsed',
                                style: theme.textTheme.titleSmall,),
                            if (_result!.warnings.isNotEmpty)
                              Text(
                                '${_result!.warnings.length} line(s) skipped',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                          ],
                        ),
                      ),
                      if (widget.targetDeckId == null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _newDeckTitleController,
                          decoration: const InputDecoration(
                              labelText: 'New deck title',),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _result!.cards.isEmpty ? null : _commit,
                        child: Text(widget.targetDeckId == null
                            ? 'Create deck'
                            : 'Add to deck',),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
