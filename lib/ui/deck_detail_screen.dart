import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/add_cards_sheet.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/card_editor_screen.dart';
import 'package:komak/ui/deck_editor_screen.dart';
import 'package:komak/ui/export_sheet.dart';
import 'package:komak/ui/learn_session_screen.dart';
import 'package:komak/ui/practice_menu_screen.dart';
import 'package:komak/ui/study_session_screen.dart';
import 'package:komak/ui/widgets/card_tile.dart';
import 'package:komak/ui/widgets/deck_card.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/entrance_view.dart';
import 'package:komak/ui/widgets/group_dialog.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/theme_toggle_button.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  static const double _cardMaxExtent = 280;
  static const double _cardExtent = 176;
  static const double _chipBarHeight = 40;
  static const double _toggleSize = 40;

  String _query = '';
  String? _group;
  final _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  List<Flashcard> _visible(Deck deck) {
    return deck.cards
        .where(
          (c) => (_group == null || c.groupId == _group) && c.matches(_query),
        )
        .toList();
  }

  Future<void> _deleteSelected(AppController controller, Deck deck) async {
    final ids = Set<String>.of(_selected);
    final messenger = ScaffoldMessenger.of(context);
    final removed = await controller.deleteCards(deck.id, ids);
    if (!mounted) return;
    setState(_selected.clear);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text.verbatim(
            L10n.fmt('{} cards deleted', [removed.length]),
          ),
          action: SnackBarAction(
            label: 'Undo'.tr,
            onPressed: () =>
                unawaited(controller.restoreCards(deck.id, removed)),
          ),
        ),
      );
  }

  Future<void> _groupSelected(AppController controller, Deck deck) async {
    final result = await showGroupDialog(context, deck.groups);
    if (result == null || !mounted) return;
    await controller.setCardsGroup(deck.id, Set.of(_selected), result.group);
    if (!mounted) return;
    setState(_selected.clear);
  }

  Future<void> _resetSelected(AppController controller, Deck deck) async {
    await controller.resetCardProgress(deck.id, Set.of(_selected));
    if (!mounted) return;
    setState(_selected.clear);
  }

  Future<void> _removeDuplicates(AppController controller, Deck deck) async {
    final messenger = ScaffoldMessenger.of(context);
    final removed = await controller.removeDuplicateCards(deck.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text.verbatim(
            removed == 0
                ? 'No duplicates found'.tr
                : L10n.fmt('{} duplicates removed', [removed]),
          ),
        ),
      );
  }

  Future<void> _deleteCard(
    AppController controller,
    Deck deck,
    Flashcard card,
  ) async {
    final index = deck.cards.indexOf(card);
    final messenger = ScaffoldMessenger.of(context);
    await controller.deleteCard(deck.id, card.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Card deleted'),
        action: SnackBarAction(
          label: 'Undo'.tr,
          onPressed: () => controller.insertCard(deck.id, index, card),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDeck(AppController controller, Deck deck) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text.verbatim(L10n.fmt('Delete {}?', <Object?>[deck.title])),
          content: Text(
            'This removes the deck and its ${deck.cards.length} cards from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final index = controller.indexOfDeck(deck.id);
    navigator.pop();
    await controller.deleteDeck(deck.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text.verbatim(L10n.fmt('{} deleted', <Object?>[deck.title])),
        action: SnackBarAction(
          label: 'Undo'.tr,
          onPressed: () => controller.insertDeck(index, deck),
        ),
      ),
    );
  }

  List<Widget> _buildCardSlivers(AppController controller, Deck deck) {
    final theme = Theme.of(context);
    final visible = _visible(deck);
    final groupCounts = deck.groupCounts;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search cards'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => showAddCardsSheet(context, deck),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add cards'),
              ),
            ],
          ),
        ),
      ),
      if (groupCounts.length > 1)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SizedBox(
              height: _chipBarHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xxs,
                    ),
                    child: ChoiceChip(
                      label: Text.verbatim(
                        L10n.fmt('All ({})', [deck.cards.length]),
                      ),
                      selected: _group == null,
                      onSelected: (_) => setState(() => _group = null),
                    ),
                  ),
                  for (final entry in groupCounts.entries)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xxs,
                      ),
                      child: ChoiceChip(
                        label: Text.verbatim('${entry.key} (${entry.value})'),
                        selected: _group == entry.key,
                        onSelected: (_) => setState(
                          () => _group = _group == entry.key ? null : entry.key,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      if (deck.cards.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: EmptyStateView(
              icon: Icons.style_outlined,
              title: 'No cards yet',
              message:
                  'Add a card by hand, paste a few lines of CSV, or import a whole file.',
              action: FilledButton.icon(
                onPressed: () => showAddCardsSheet(context, deck),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add cards'),
              ),
            ),
          ),
        )
      else if (visible.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Text.verbatim(
              L10n.fmt('No cards match "{}".', <Object?>[_query]),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        )
      else
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _cardMaxExtent,
            mainAxisExtent: _cardExtent,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final card = visible[index];
              return EntranceView(
                key: ValueKey(card.id),
                index: index % 8,
                child: CardTile(
                  card: card,
                  accent: deck.accentColor,
                  selectionMode: _selecting,
                  selected: _selected.contains(card.id),
                  onLongPress: () => _toggle(card.id),
                  onTap: () {
                    if (_selecting) {
                      _toggle(card.id);
                      return;
                    }
                    unawaited(
                      AppRoutes.push<void>(
                        context,
                        CardEditorScreen(deckId: deck.id, existingCard: card),
                      ),
                    );
                  },
                  onDelete: () => unawaited(_deleteCard(controller, deck, card)),
                ),
              );
            },
            childCount: visible.length,
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final deck = controller.deckByIdOrNull(widget.deckId);
    if (deck == null) return const Scaffold(body: SizedBox.shrink());

    final visible = _visible(deck);

    final appBar = _selecting
        ? AppBar(
            leading: IconButton(
              tooltip: 'Close selection'.tr,
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close_rounded),
            ),
            title: Text.verbatim(
              L10n.fmt('{} selected', [_selected.length]),
            ),
            actions: [
              IconButton(
                tooltip: 'Select all'.tr,
                onPressed: () => setState(
                  () => _selected.addAll(visible.map((c) => c.id)),
                ),
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                tooltip: 'Set group'.tr,
                onPressed: () => unawaited(_groupSelected(controller, deck)),
                icon: const Icon(Icons.folder_open_rounded),
              ),
              IconButton(
                tooltip: 'Delete'.tr,
                onPressed: () => unawaited(_deleteSelected(controller, deck)),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              PopupMenuButton<String>(
                tooltip: 'More'.tr,
                onSelected: (value) {
                  if (value == 'reset') {
                    unawaited(_resetSelected(controller, deck));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset learning progress'),
                  ),
                ],
              ),
            ],
          )
        : AppBar(
            title: Text.verbatim(
              deck.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              const ThemeToggleButton(size: _toggleSize),
              PopupMenuButton<String>(
                tooltip: 'More'.tr,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      unawaited(
                        AppRoutes.push<void>(
                          context,
                          DeckEditorScreen(deckId: deck.id),
                        ),
                      );
                    case 'practice':
                      unawaited(
                        AppRoutes.push<void>(
                          context,
                          PracticeMenuScreen(deckId: deck.id),
                        ),
                      );
                    case 'duplicates':
                      unawaited(_removeDuplicates(controller, deck));
                    case 'export':
                      unawaited(showExportSheet(context, deck));
                    case 'delete':
                      unawaited(_confirmDeleteDeck(controller, deck));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit deck')),
                  PopupMenuItem(
                    value: 'practice',
                    child: Text('Practice settings'),
                  ),
                  PopupMenuItem(
                    value: 'duplicates',
                    child: Text('Remove duplicate cards'),
                  ),
                  PopupMenuItem(value: 'export', child: Text('Export')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Text('Delete deck')),
                ],
              ),
            ],
          );

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: appBar,
      body: SafeArea(
        child: PageFrame(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: EntranceView(
                    child: DeckCard(
                      deck: deck,
                      onLearn: () => unawaited(
                        AppRoutes.push<void>(
                          context,
                          LearnSessionScreen(deckId: deck.id),
                        ),
                      ),
                      onStudy: () => unawaited(
                        AppRoutes.push<void>(
                          context,
                          StudySessionScreen(deckId: deck.id),
                        ),
                      ),
                      onPractice: () => unawaited(
                        AppRoutes.push<void>(
                          context,
                          PracticeMenuScreen(deckId: deck.id),
                        ),
                      ),
                      onPracticeSettings: () => unawaited(
                        AppRoutes.push<void>(
                          context,
                          PracticeMenuScreen(deckId: deck.id),
                        ),
                      ),
                      onEdit: () => unawaited(
                        AppRoutes.push<void>(
                          context,
                          DeckEditorScreen(deckId: deck.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ..._buildCardSlivers(controller, deck),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
