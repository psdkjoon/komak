import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/app_icon.dart';
import 'package:komak/platform/haptics_service.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/bulk_edit_sheet.dart';
import 'package:komak/ui/deck_detail_screen.dart';
import 'package:komak/ui/deck_editor_screen.dart';
import 'package:komak/ui/import_screen.dart';
import 'package:komak/ui/store_screen.dart';
import 'package:komak/ui/widgets/deck_tile.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/entrance_view.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/streak_card.dart';
import 'package:komak/ui/widgets/theme_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _tileExtent = 132;
  static const double _tileMinWidth = 190;
  static const double _edgeZone = 80;
  static const double _maxScrollSpeed = 16;
  static const double _headerHeight = 56;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _scrollKey = GlobalKey();
  final Map<String, GlobalKey> _tileKeys = <String, GlobalKey>{};

  Set<String> _selected = <String>{};
  Set<String> _dragBase = <String>{};
  int? _anchor;
  int? _current;
  Offset? _pointer;
  Timer? _scrollTimer;
  double _scrollVelocity = 0;

  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String deckId) =>
      _tileKeys.putIfAbsent(deckId, GlobalKey.new);

  void _clearSelection() {
    _stopDrag();
    setState(() => _selected = <String>{});
  }

  void _toggle(String deckId) {
    final next = Set<String>.of(_selected);
    if (!next.remove(deckId)) next.add(deckId);
    setState(() => _selected = next);
  }

  void _selectAll(List<Deck> decks) {
    setState(() => _selected = decks.map((Deck d) => d.id).toSet());
  }

  int? _indexAt(Offset global, List<Deck> decks) {
    for (int i = 0; i < decks.length; i++) {
      final context = _tileKeys[decks[i].id]?.currentContext;
      if (context == null) continue;
      final object = context.findRenderObject();
      if (object is! RenderBox || !object.attached || !object.hasSize) {
        continue;
      }
      final local = object.globalToLocal(global);
      if (local.dx >= 0 &&
          local.dy >= 0 &&
          local.dx <= object.size.width &&
          local.dy <= object.size.height) {
        return i;
      }
    }
    return null;
  }

  void _onLongPressStart(int index, LongPressStartDetails details) {
    final controller = AppScope.read(context);
    final decks = controller.decks;
    if (index >= decks.length) return;
    unawaited(HapticsService.select());
    _dragBase = Set<String>.of(_selected);
    _anchor = index;
    _current = index;
    _pointer = details.globalPosition;
    setState(() => _selected = <String>{..._dragBase, decks[index].id});
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (_anchor == null) return;
    _pointer = details.globalPosition;
    _updateRange();
    _updateAutoScroll();
  }

  void _updateRange() {
    final anchor = _anchor;
    final pointer = _pointer;
    if (anchor == null || pointer == null || !mounted) return;
    final decks = AppScope.read(context).decks;
    final hit = _indexAt(pointer, decks);
    if (hit == null || hit == _current) return;
    _current = hit;
    final low = math.min(anchor, hit);
    final high = math.max(anchor, hit);
    setState(() {
      _selected = <String>{
        ..._dragBase,
        for (int i = low; i <= high && i < decks.length; i++) decks[i].id,
      };
    });
    unawaited(HapticsService.select());
  }

  void _updateAutoScroll() {
    final object = _scrollKey.currentContext?.findRenderObject();
    final pointer = _pointer;
    if (object is! RenderBox || pointer == null) return;
    final top = object.localToGlobal(Offset.zero).dy;
    final bottom = top + object.size.height;
    double velocity = 0;
    if (pointer.dy < top + _edgeZone) {
      velocity = -((top + _edgeZone - pointer.dy) / _edgeZone)
              .clamp(0.0, 1.0)
              .toDouble() *
          _maxScrollSpeed;
    } else if (pointer.dy > bottom - _edgeZone) {
      velocity = ((pointer.dy - (bottom - _edgeZone)) / _edgeZone)
              .clamp(0.0, 1.0)
              .toDouble() *
          _maxScrollSpeed;
    }
    _scrollVelocity = velocity;
    if (velocity == 0) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    } else {
      _scrollTimer ??= Timer.periodic(
        const Duration(milliseconds: 16),
        (Timer _) => _autoScrollTick(),
      );
    }
  }

  void _autoScrollTick() {
    if (!_scroll.hasClients || _scrollVelocity == 0) return;
    final position = _scroll.position;
    final next = (position.pixels + _scrollVelocity)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (next == position.pixels) return;
    _scroll.jumpTo(next);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _updateRange();
    });
  }

  void _stopDrag() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _scrollVelocity = 0;
    _anchor = null;
    _current = null;
    _pointer = null;
  }

  void _onLongPressEnd(LongPressEndDetails details) => _stopDrag();

  Future<void> _edit(AppController controller) async {
    if (_selected.length == 1) {
      final id = _selected.first;
      await AppRoutes.push<void>(context, DeckEditorScreen(deckId: id));
      if (mounted) _clearSelection();
      return;
    }
    final applied = await showBulkEditSheet(context, _selected);
    if (applied && mounted) _clearSelection();
  }

  Future<void> _delete(AppController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final ids = Set<String>.of(_selected);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: ids.length == 1
              ? Text.verbatim(
                  L10n.fmt(
                    'Delete {}?',
                    <Object?>[controller.deckById(ids.first).title],
                  ),
                )
              : Text('Delete ${ids.length} decks?'),
          content: const Text(
            'This removes the selected decks and all their cards from this device.',
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
    final removed = await controller.deleteDecks(ids);
    if (!mounted) return;
    _clearSelection();
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${removed.length} decks deleted'),
        action: SnackBarAction(
          label: 'Undo'.tr,
          onPressed: () => controller.restoreDecks(removed),
        ),
      ),
    );
  }

  Future<void> _move(AppController controller, int delta) =>
      controller.moveDecks(_selected, delta);

  Future<void> _moveToEdge(AppController controller, bool toStart) =>
      controller.moveDecksToEdge(_selected, toStart: toStart);

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final decks = controller.decks;
    final liveIds = decks.map((Deck d) => d.id).toSet();
    _tileKeys.removeWhere((String id, GlobalKey _) => !liveIds.contains(id));
    if (_selected.any((String id) => !liveIds.contains(id))) {
      _selected = _selected.where(liveIds.contains).toSet();
    }

    final status = Theme.of(context).extension<StatusColors>()!;
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, 1.6)
        .toDouble();
    final tileExtent = _tileExtent + (textScale - 1) * 70;

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selecting) _clearSelection();
      },
      child: Column(
        children: [
          Expanded(
            child: PageFrame(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = math.max(
                    2,
                    ((constraints.maxWidth + AppSpacing.sm) /
                            (_tileMinWidth + AppSpacing.sm))
                        .floor(),
                  );
                  return CustomScrollView(
                    key: _scrollKey,
                    controller: _scroll,
                    slivers: [
                      SliverToBoxAdapter(
                        child: EntranceView(
                          child: SizedBox(
                            height: _headerHeight,
                            child: AnimatedSwitcher(
                              duration: AppMotion.resolve(
                                context,
                                AppMotion.quick,
                              ),
                              child: _selecting
                                  ? _SelectionHeader(
                                      key: const ValueKey('selection'),
                                      count: _selected.length,
                                      onClose: _clearSelection,
                                      onSelectAll: () => _selectAll(decks),
                                    )
                                  : const _HomeHeader(key: ValueKey('header')),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: EntranceView(
                            index: 1,
                            child: StreakCard(
                              days: controller.streak.currentStreak,
                              color: status.streak,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.sm,
                          ),
                          child: EntranceView(
                            index: 2,
                            child: _DecksToolbar(),
                          ),
                        ),
                      ),
                      if (decks.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateView(
                            icon: Icons.auto_awesome_rounded,
                            title: 'No decks yet',
                            message:
                                'Create a deck, import one, or find one in the store.',
                            action: FilledButton.icon(
                              onPressed: () => AppRoutes.push<void>(
                                context,
                                const DeckEditorScreen(),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create a deck'),
                            ),
                          ),
                        )
                      else
                        SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisExtent: tileExtent,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final deck = decks[index];
                              return EntranceView(
                                key: _keyFor(deck.id),
                                index: index,
                                child: DeckTile(
                                  deck: deck,
                                  selecting: _selecting,
                                  selected: _selected.contains(deck.id),
                                  onTap: () {
                                    if (_selecting) {
                                      _toggle(deck.id);
                                    } else {
                                      unawaited(
                                        AppRoutes.push<void>(
                                          context,
                                          DeckDetailScreen(deckId: deck.id),
                                        ),
                                      );
                                    }
                                  },
                                  onLongPressStart: (details) =>
                                      _onLongPressStart(index, details),
                                  onLongPressMoveUpdate: _onLongPressMove,
                                  onLongPressEnd: _onLongPressEnd,
                                ),
                              );
                            },
                            childCount: decks.length,
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxl),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.quick),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: child,
            ),
            child: _selecting
                ? _SelectionBar(
                    key: const ValueKey('selection-bar'),
                    onEdit: () => _edit(controller),
                    onEarlier: () => _move(controller, -1),
                    onLater: () => _move(controller, 1),
                    onToStart: () => _moveToEdge(controller, true),
                    onToEnd: () => _moveToEdge(controller, false),
                    onDelete: () => _delete(controller),
                  )
                : const SizedBox.shrink(key: ValueKey('no-bar')),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      spacing: AppSpacing.sm,
      children: [
        Expanded(
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Flexible(
                child: Text(
                  'komak',
                  style: theme.textTheme.displaySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Image.asset(
                AppIcon.logo(theme.brightness),
                width: 30,
                height: 30,
                excludeFromSemantics: true,
              ),
            ],
          ),
        ),
        const ThemeToggleButton(),
      ],
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    super.key,
    required this.count,
    required this.onClose,
    required this.onSelectAll,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      spacing: AppSpacing.sm,
      children: [
        IconButton.filledTonal(
          tooltip: 'Close selection'.tr,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            fixedSize: const Size(48, 48),
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            foregroundColor: theme.colorScheme.onSurface,
            shape: const CircleBorder(),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count selected',
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (count == 1)
                Text(
                  'Long-press and drag to select a range',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onSelectAll,
          icon: const Icon(Icons.select_all_rounded),
          label: const Text('Select all', maxLines: 1),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    super.key,
    required this.onEdit,
    required this.onEarlier,
    required this.onLater,
    required this.onToStart,
    required this.onToEnd,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onEarlier;
  final VoidCallback onLater;
  final VoidCallback onToStart;
  final VoidCallback onToEnd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _BarAction(
              icon: Icons.edit_rounded,
              label: 'Edit',
              onTap: onEdit,
            ),
            _BarAction(
              icon: Icons.vertical_align_top_rounded,
              label: 'To start',
              onTap: onToStart,
            ),
            _BarAction(
              icon: Icons.arrow_upward_rounded,
              label: 'Earlier',
              onTap: onEarlier,
            ),
            _BarAction(
              icon: Icons.arrow_downward_rounded,
              label: 'Later',
              onTap: onLater,
            ),
            _BarAction(
              icon: Icons.vertical_align_bottom_rounded,
              label: 'To end',
              onTap: onToEnd,
            ),
            _BarAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: onDelete,
              color: scheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurface;

    return Expanded(
      child: Tooltip(
        message: label.tr,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Icon(icon, size: 24, color: tint),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecksToolbar extends StatelessWidget {
  const _DecksToolbar();

  static const Size _buttonSize = Size(0, 44);
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.sm,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text('Your decks', style: theme.textTheme.headlineSmall),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    AppRoutes.push<void>(context, const ImportScreen()),
                style: OutlinedButton.styleFrom(
                  minimumSize: _buttonSize,
                  padding: _buttonPadding,
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                label: const Text(
                  'Import',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    AppRoutes.push<void>(context, const DeckEditorScreen()),
                style: FilledButton.styleFrom(
                  minimumSize: _buttonSize,
                  padding: _buttonPadding,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'New deck',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Deck store'.tr,
              onPressed: () =>
                  AppRoutes.push<void>(context, const StoreScreen()),
              icon: const Icon(Icons.storefront_rounded),
              style: IconButton.styleFrom(fixedSize: const Size(44, 44)),
            ),
          ],
        ),
      ],
    );
  }
}
