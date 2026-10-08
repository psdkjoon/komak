import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/services/import_result.dart';
import 'package:komak/core/services/network_import_service.dart';
import 'package:komak/core/services/store_service.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final StoreService _store = StoreService();
  final NetworkImportService _importer = NetworkImportService();
  final TextEditingController _search = TextEditingController();
  final Set<String> _adding = <String>{};

  List<StoreEntry> _entries = <StoreEntry>[];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
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
      final List<StoreEntry> entries = await _store.fetchIndex();
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
    final AppController controller = AppScope.read(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _adding.add(entry.url));
    try {
      final ImportResult result = await _importer.importFromUrl(entry.url);
      if (result.cards.isEmpty) {
        messenger.showSnackBar(
            const SnackBar(content: Text('That deck has no cards.')),);
        return;
      }
      await controller.addDeck(
        Deck(
          title: entry.title,
          description: entry.description.isNotEmpty
              ? entry.description
              : (result.deckDescription ?? 'From the deck store.'),
          accentColorValue: 0xFF89DCEB,
          iconKey: 'download',
          cards: result.cards,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text('Added ${entry.title}')));
    } on NetworkImportException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not add that deck: $error')),);
    } finally {
      if (mounted) setState(() => _adding.remove(entry.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final ThemeData theme = Theme.of(context);
    final List<StoreEntry> visible =
        _entries.where((StoreEntry e) => e.matches(_query)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Deck store')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.readableMaxWidth),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.md, AppSpacing.lg, AppSpacing.sm,),
                  child: TextField(
                    controller: _search,
                    onChanged: (String value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search decks',
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
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? EmptyState(
                              icon: Icons.cloud_off_rounded,
                              title: 'Store unavailable',
                              message: _error!,
                              action: FilledButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Try again'),
                              ),
                            )
                          : visible.isEmpty
                              ? const EmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: 'No decks found',
                                  message: 'Try a different search.',
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: AnimatedBuilder(
                                    animation: controller,
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            AppSpacing.lg,
                                            AppSpacing.xs,
                                            AppSpacing.lg,
                                            AppSpacing.xl,),
                                        itemCount: visible.length,
                                        separatorBuilder:
                                            (BuildContext context, int index) =>
                                                const SizedBox(
                                                    height: AppSpacing.sm,),
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          final StoreEntry entry =
                                              visible[index];
                                          final bool added = controller.decks
                                              .any((Deck d) =>
                                                  d.title == entry.title,);
                                          final bool adding =
                                              _adding.contains(entry.url);
                                          return SectionCard(
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Text(entry.title,
                                                          style: theme.textTheme
                                                              .titleMedium,),
                                                      if (entry.description
                                                          .isNotEmpty) ...<Widget>[
                                                        const SizedBox(
                                                            height: 2,),
                                                        Text(
                                                          entry.description,
                                                          style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  color: theme
                                                                      .colorScheme
                                                                      .onSurfaceVariant,),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: AppSpacing.sm,),
                                                if (adding)
                                                  const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2.5,),)
                                                else if (added)
                                                  Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      color: theme
                                                          .colorScheme.primary,)
                                                else
                                                  FilledButton.tonal(
                                                      onPressed: () =>
                                                          _add(entry),
                                                      child: const Text('Add'),),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
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
