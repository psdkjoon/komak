import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/questions/memory_question.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/features/practice/practice_feedback.dart';

class _MemoryTile {
  const _MemoryTile({required this.cardId, required this.text});

  final String cardId;
  final String text;
}

class MemoryWidget extends StatefulWidget {
  const MemoryWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  final MemoryQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<MemoryWidget> createState() => _MemoryWidgetState();
}

class _MemoryWidgetState extends State<MemoryWidget> {
  late final List<_MemoryTile> _tiles;
  final List<int> _revealed = <int>[];
  final Set<String> _matched = <String>{};
  List<int> _wrongPair = <int>[];
  bool _busy = false;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _tiles = <_MemoryTile>[
      for (final Flashcard card in widget.question.pairs) ...<_MemoryTile>[
        _MemoryTile(cardId: card.id, text: card.front),
        _MemoryTile(cardId: card.id, text: card.back),
      ],
    ]..shuffle();
  }

  void _tap(int index) {
    if (_busy ||
        _revealed.contains(index) ||
        _matched.contains(_tiles[index].cardId)) {
      return;
    }
    setState(() => _revealed.add(index));
    if (_revealed.length < 2) return;

    final _MemoryTile first = _tiles[_revealed[0]];
    final _MemoryTile second = _tiles[_revealed[1]];

    if (first.cardId == second.cardId) {
      final bool done = _matched.length + 1 == widget.question.pairs.length;
      PracticeFeedback.report(context, true, big: done && _mistakes <= 2);
      setState(() {
        _matched.add(first.cardId);
        _revealed.clear();
      });
      if (done) {
        Future<void>.delayed(AppMotion.resolve(context, Durations.extralong1),
            () {
          if (mounted) {
            widget.onAnswered(
              _mistakes <= 2,
              widget.question.pairs.map((Flashcard c) => c.id).toList(),
            );
          }
        });
      }
    } else {
      _mistakes += 1;
      PracticeFeedback.report(context, false, big: false);
      setState(() {
        _busy = true;
        _wrongPair = List<int>.from(_revealed);
      });
      Future<void>.delayed(AppMotion.resolve(context, Durations.extralong1),
          () {
        if (!mounted) return;
        setState(() {
          _revealed.clear();
          _wrongPair = <int>[];
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Match each item with its pair',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2,
            children: <Widget>[
              for (int i = 0; i < _tiles.length; i++)
                _TileView(
                  text: _tiles[i].text,
                  faceUp: _revealed.contains(i) ||
                      _matched.contains(_tiles[i].cardId),
                  matched: _matched.contains(_tiles[i].cardId),
                  wrong: _wrongPair.contains(i),
                  onTap: () => _tap(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({
    required this.text,
    required this.faceUp,
    required this.matched,
    required this.wrong,
    required this.onTap,
  });

  final String text;
  final bool faceUp;
  final bool matched;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Color background = scheme.primaryContainer.withValues(alpha: 0.5);
    Color border = scheme.primary.withValues(alpha: 0.5);
    if (faceUp) {
      background = scheme.surfaceContainerHigh;
      border = scheme.primary;
    }
    if (matched) {
      background = scheme.secondaryContainer;
      border = scheme.secondary;
    }
    if (wrong) {
      background = scheme.errorContainer;
      border = scheme.error;
    }

    return AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.quick),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border, width: 1.6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: faceUp ? null : onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: AnimatedSwitcher(
                duration: AppMotion.resolve(context, AppMotion.quick),
                child: faceUp
                    ? Text(
                        text,
                        key: ValueKey<String>('up-$text'),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      )
                    : Icon(
                        Icons.question_mark_rounded,
                        key: const ValueKey<String>('down'),
                        color: scheme.primary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
