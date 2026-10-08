import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_route.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/entrance_animation.dart';
import 'package:komak/core/widgets/handshake_mark.dart';
import 'package:komak/core/widgets/sliver_content.dart';
import 'package:komak/core/widgets/theme_toggle_button.dart';
import 'package:komak/core/theme/app_colors_extension.dart';
import 'package:komak/features/deck/deck_detail_screen.dart';
import 'package:komak/features/deck/deck_editor_screen.dart';
import 'package:komak/features/home/widgets/deck_tile.dart';
import 'package:komak/features/home/widgets/streak_card.dart';
import 'package:komak/features/store/store_screen.dart';
import 'package:komak/features/import_export/import_screen.dart';
import 'package:komak/features/settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<Deck> decks = controller.decks;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            const SliverBox(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: EntranceAnimation(child: _HomeHeader()),
              ),
            ),
            SliverBox(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: EntranceAnimation(
                  index: 1,
                  child: StreakCard(
                    days: controller.streak.currentStreak,
                    color: context.appColors.streak,
                  ),
                ),
              ),
            ),
            SliverBox(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.xl, bottom: AppSpacing.md,),
                child: EntranceAnimation(
                    index: 2, child: _DecksToolbar(count: decks.length),),
              ),
            ),
            if (decks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.auto_awesome_rounded,
                  title: 'No decks yet',
                  message:
                      'Create a deck, import one, or find one in the store.',
                  action: FilledButton.icon(
                    onPressed: () =>
                        AppRoutes.push<void>(context, const DeckEditorScreen()),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create a deck'),
                  ),
                ),
              )
            else
              SliverContent(
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 196,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final Deck deck = decks[index];
                      return EntranceAnimation(
                        key: ValueKey<String>(deck.id),
                        index: index,
                        child: DeckTile(
                          deck: deck,
                          onTap: () => AppRoutes.push<void>(
                              context, DeckDetailScreen(deckId: deck.id),),
                        ),
                      );
                    },
                    childCount: decks.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text('komak',
                        style: theme.textTheme.displaySmall,
                        overflow: TextOverflow.ellipsis,),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const HandshakeMark(size: 30),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const ThemeToggleButton(),
        const SizedBox(width: AppSpacing.xs),
        Tooltip(
          message: 'Settings',
          child: IconButton.filledTonal(
            onPressed: () =>
                AppRoutes.push<void>(context, const SettingsScreen()),
            icon: const Icon(Icons.settings_rounded),
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              foregroundColor: theme.colorScheme.onSurface,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DecksToolbar extends StatelessWidget {
  const _DecksToolbar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Your decks', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    AppRoutes.push<void>(context, const ImportScreen()),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Import'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    AppRoutes.push<void>(context, const DeckEditorScreen()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New deck'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: () => AppRoutes.push<void>(context, const StoreScreen()),
          icon: const Icon(Icons.storefront_rounded),
          label: const Text('Deck store'),
        ),
      ],
    );
  }
}
