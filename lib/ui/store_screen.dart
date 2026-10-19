import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/core/card_intake.dart';
import 'package:komak/core/network_importer.dart';
import 'package:komak/core/store_client.dart';
import 'package:komak/core/store_entry.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/intake_notice.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/page_frame.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _store = StoreClient();
  final _importer = NetworkImporter();
  final _search = TextEditingController();
  final _adding = <String>{};

  List<StoreEntry> _entries = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _store.fetchIndex();
      if (!mounted) return;
      setState(() => _entries = entries);
    } on StoreException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(StoreEntry entry) async {
    final controller = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding.add(entry.url));
    try {
      final result = await _importer.importFromUrl(entry.url);
      if (result.cards.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('That deck has no cards.')),
        );
        return;
      }
      final intake = CardIntake.prepare(const <Flashcard>[], result.cards);
      await controller.addDeck(
        Deck(
          title: entry.title,
          description: entry.description.isNotEmpty
              ? entry.description
              : (result.deckDescription ?? 'From the deck store.'.tr),
          accentColorValue: 0xFF89DCEB,
          iconKey: 'download',
          cards: intake.accepted,
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text.verbatim('${entry.title}: ${intakeMessage(intake)}'),
        ),
      );
    } on NetworkImportException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add that deck: $error')),
      );
    } finally {
      if (mounted) setState(() => _adding.remove(entry.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final visible = _entries.where((e) => e.matches(_query)).toList();

    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Store unavailable',
        message: _error!,
        action: FilledButton.icon(
          onPressed: () => unawaited(_load()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    } else if (visible.isEmpty) {
      body = const EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No decks found',
        message: 'Try a different search.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: visible.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = visible[index];
                return _StoreEntryCard(
                  entry: entry,
                  added: controller.decks.any((d) => d.title == entry.title),
                  adding: _adding.contains(entry.url),
                  onAdd: () => unawaited(_add(entry)),
                );
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Deck store')),
      body: SafeArea(
        child: PageFrame(
          child: Column(
            spacing: AppSpacing.sm,
            children: [
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search decks'.tr,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreEntryCard extends StatelessWidget {
  const _StoreEntryCard({
    required this.entry,
    required this.added,
    required this.adding,
    required this.onAdd,
  });

  final StoreEntry entry;
  final bool added;
  final bool adding;
  final VoidCallback onAdd;

  static const double _spinnerSize = 24;
  static const double _spinnerStroke = 2.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text.verbatim(entry.title, style: theme.textTheme.titleMedium),
                  if (entry.description.isNotEmpty)
                    Text.verbatim(
                      entry.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (adding)
              const SizedBox(
                width: _spinnerSize,
                height: _spinnerSize,
                child: CircularProgressIndicator(strokeWidth: _spinnerStroke),
              )
            else if (added)
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            else
              FilledButton.tonal(onPressed: onAdd, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}
