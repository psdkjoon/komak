import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_route.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/entrance_animation.dart';
import 'package:komak/core/widgets/sliver_content.dart';
import 'package:komak/core/widgets/theme_toggle_button.dart';
import 'package:komak/features/card_editor/card_editor_screen.dart';
import 'package:komak/features/deck/add_cards_sheet.dart';
import 'package:komak/features/deck/deck_editor_screen.dart';
import 'package:komak/features/deck/practice_settings_sheet.dart';
import 'package:komak/features/deck/widgets/card_tile.dart';
import 'package:komak/features/deck/widgets/deck_panel.dart';
import 'package:komak/features/import_export/export_sheet.dart';
import 'package:komak/features/practice/practice_session_screen.dart';
import 'package:komak/features/study/study_session_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  String _query = '';

  Future<void> _deleteCard(
    AppController controller,
    Deck deck,
    Flashcard card,
  ) async {
    final int index = deck.cards.indexOf(card);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await controller.deleteCard(deck.id, card.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Card deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.insertCard(deck.id, index, card),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDeck(AppController controller, Deck deck) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete ${deck.title}?'),
          content: Text(
            'This removes the deck and its ${deck.cards.length} cards from this device.',
          ),
          actions: <Widget>[
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

    final int index = controller.indexOfDeck(deck.id);
    navigator.pop();
    await controller.deleteDeck(deck.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${deck.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.insertDeck(index, deck),
        ),
      ),
    );
  }

  List<Widget> _buildCardSlivers(
    AppController controller,
    Deck deck, {
    required bool wrap,
  }) {
    final ThemeData theme = Theme.of(context);
    final String needle = _query.trim().toLowerCase();
    final List<Flashcard> visible = needle.isEmpty
        ? deck.cards
        : deck.cards
            .where(
              (Flashcard c) =>
                  c.front.toLowerCase().contains(needle) ||
                  c.back.toLowerCase().contains(needle),
            )
            .toList();

    Widget place(Widget sliver) =>
        wrap ? SliverContent(sliver: sliver) : sliver;

    return <Widget>[
      place(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search cards',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: () => showAddCardsSheet(context, deck),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add cards'),
                ),
              ],
            ),
          ),
        ),
      ),
      if (deck.cards.isEmpty)
        place(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: EmptyState(
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
          ),
        )
      else if (visible.isEmpty)
        place(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No cards match "$_query".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        )
      else
        place(
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisExtent: 156,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final Flashcard card = visible[index];
                return EntranceAnimation(
                  key: ValueKey<String>(card.id),
                  index: index % 8,
                  child: CardTile(
                    card: card,
                    accent: deck.accentColor,
                    onTap: () => AppRoutes.push<void>(
                      context,
                      CardEditorScreen(deckId: deck.id, existingCard: card),
                    ),
                    onDelete: () => _deleteCard(controller, deck, card),
                  ),
                );
              },
              childCount: visible.length,
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final Deck? deck = controller.deckByIdOrNull(widget.deckId);
    if (deck == null) return const Scaffold(body: SizedBox.shrink());

    final Widget panel = DeckPanel(
      deck: deck,
      onStudy: () =>
          AppRoutes.push<void>(context, StudySessionScreen(deckId: deck.id)),
      onPractice: () =>
          AppRoutes.push<void>(context, PracticeSessionScreen(deckId: deck.id)),
      onPracticeSettings: () => showPracticeSettingsSheet(context, deck.id),
      onEdit: () =>
          AppRoutes.push<void>(context, DeckEditorScreen(deckId: deck.id)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          const ThemeToggleButton(size: 40),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  AppRoutes.push<void>(
                    context,
                    DeckEditorScreen(deckId: deck.id),
                  );
                case 'practice':
                  showPracticeSettingsSheet(context, deck.id);
                case 'export':
                  showExportSheet(context, deck);
                case 'delete':
                  _confirmDeleteDeck(controller, deck);
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('Edit deck')),
              PopupMenuItem<String>(
                value: 'practice',
                child: Text('Practice settings'),
              ),
              PopupMenuItem<String>(value: 'export', child: Text('Export')),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete deck'),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide =
                constraints.maxWidth >= AppLayout.expandedMinWidth;

            if (wide) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: AppLayout.sidePanelWidth,
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xl),
                            child: EntranceAnimation(child: panel),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: CustomScrollView(
                            slivers: _buildCardSlivers(
                              controller,
                              deck,
                              wrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverBox(
                  maxWidth: AppLayout.readableMaxWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: EntranceAnimation(child: panel),
                  ),
                ),
                ..._buildCardSlivers(controller, deck, wrap: true),
              ],
            );
          },
        ),
      ),
    );
  }
}
