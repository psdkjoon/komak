import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/empty_state_view.dart';
import 'package:komak/ui/widgets/flip_card.dart';
import 'package:komak/ui/widgets/page_frame.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  late final AppController _controller;
  late List<Flashcard> _cards;
  final _pageController = PageController();
  final _flippedPages = <int>{};
  int _page = 0;
  bool _shuffled = false;

  @override
  void initState() {
    super.initState();
    _controller = AppScope.read(context);
    _cards = List.of(_controller.deckById(widget.deckId).cards);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleShuffle() {
    setState(() {
      _shuffled = !_shuffled;
      _flippedPages.clear();
      _cards = List.of(_controller.deckById(widget.deckId).cards);
      if (_shuffled) _cards.shuffle();
    });
    _pageController.jumpToPage(0);
    setState(() => _page = 0);
  }

  void _flip() {
    unawaited(SoundService.play(AppSound.flip));
    setState(() {
      if (!_flippedPages.add(_page)) _flippedPages.remove(_page);
    });
  }

  void _go(int delta) {
    final next = (_page + delta).clamp(0, _cards.length - 1);
    if (next == _page) return;
    unawaited(
      _pageController.animateToPage(
        next,
        duration: AppMotion.resolve(context, AppMotion.standard),
        curve: AppMotion.emphasizedCurve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = _controller.deckById(widget.deckId);
    final theme = Theme.of(context);

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text.verbatim(
            deck.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const EmptyStateView(
          icon: Icons.auto_stories_outlined,
          title: 'No cards yet',
          message: 'Add some cards to start studying.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text.verbatim(
          deck.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: (_shuffled ? 'Shuffled' : 'In order').tr,
            onPressed: _toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: _shuffled ? deck.accentColor : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PageFrame(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  'Card ${_page + 1} of ${_cards.length}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _cards.length,
                    onPageChanged: (int index) =>
                        setState(() => _page = index),
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                          vertical: AppSpacing.xl,
                        ),
                        child: FlipCard(
                          front: card.front,
                          back: card.back,
                          reading: card.reading,
                          example: card.example,
                          note: card.note,
                          showBack: _flippedPages.contains(index),
                          onTap: index == _page ? _flip : () {},
                          accent: deck.accentColor,
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _page > 0 ? () => _go(-1) : null,
                      icon: Icon(
                        L10n.rtl
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                      ),
                    ),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _flip,
                        icon: Icon(
                          _flippedPages.contains(_page)
                              ? Icons.visibility_off_rounded
                              : Icons.flip_rounded,
                        ),
                        label: Text(
                          _flippedPages.contains(_page)
                              ? 'Show question'
                              : 'Show answer',
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed:
                          _page < _cards.length - 1 ? () => _go(1) : null,
                      icon: Icon(
                        L10n.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
