import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/flip_card.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  late final AppController _controller;
  late List<Flashcard> _cards;
  final PageController _pageController = PageController();
  final Set<int> _flippedPages = <int>{};
  int _page = 0;
  bool _shuffled = false;

  @override
  void initState() {
    super.initState();
    _controller = AppScope.read(context);
    _cards = List<Flashcard>.from(_controller.deckById(widget.deckId).cards);
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
      _cards = List<Flashcard>.from(_controller.deckById(widget.deckId).cards);
      if (_shuffled) _cards.shuffle();
    });
    _pageController.jumpToPage(0);
    setState(() => _page = 0);
  }

  void _flip() {
    _controller.sound.play(AppSound.flip);
    setState(() {
      if (!_flippedPages.add(_page)) _flippedPages.remove(_page);
    });
  }

  void _go(int delta) {
    final int next = (_page + delta).clamp(0, _cards.length - 1);
    if (next == _page) return;
    _pageController.animateToPage(
      next,
      duration: AppMotion.resolve(context, AppMotion.standard),
      curve: AppMotion.emphasizedCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Deck deck = _controller.deckById(widget.deckId);
    final ThemeData theme = Theme.of(context);

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(deck.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: const EmptyState(
          icon: Icons.auto_stories_outlined,
          title: 'No cards yet',
          message: 'Add some cards to start studying.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: _shuffled ? 'Shuffled' : 'In order',
            onPressed: _toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: _shuffled ? deck.accentColor : null,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.sessionMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Card ${_page + 1} of ${_cards.length}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _cards.length,
                      onPageChanged: (int index) =>
                          setState(() => _page = index),
                      itemBuilder: (BuildContext context, int index) {
                        final Flashcard card = _cards[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.lg,
                          ),
                          child: FlipCard(
                            front: card.front,
                            back: card.back,
                            showBack: _flippedPages.contains(index),
                            onTap: index == _page ? _flip : () {},
                            accent: deck.accentColor,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: _page > 0 ? () => _go(-1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed:
                            _page < _cards.length - 1 ? () => _go(1) : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
