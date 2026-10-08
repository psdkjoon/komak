import 'package:flutter/material.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/models/questions/matching_question.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/features/practice/practice_feedback.dart';

class MatchingWidget extends StatefulWidget {
  const MatchingWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  final MatchingQuestion question;
  final void Function(bool correct, List<String> cardIds) onAnswered;

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> {
  late List<Flashcard> _rightOrder;
  String? _selectedLeftId;
  String? _flashWrongRightId;
  final Set<String> _matchedIds = <String>{};
  bool _hadMistake = false;

  @override
  void initState() {
    super.initState();
    _rightOrder = List<Flashcard>.from(widget.question.pairs)..shuffle();
  }

  void _tapLeft(Flashcard card) {
    if (_matchedIds.contains(card.id)) return;
    AppScope.read(context).sound.play(AppSound.tap);
    setState(() => _selectedLeftId = card.id);
  }

  void _tapRight(Flashcard rightCard) {
    if (_selectedLeftId == null || _matchedIds.contains(rightCard.id)) return;
    if (_selectedLeftId == rightCard.id) {
      PracticeFeedback.report(
        context,
        true,
        big: _matchedIds.length + 1 == widget.question.pairs.length &&
            !_hadMistake,
      );
      setState(() {
        _matchedIds.add(rightCard.id);
        _selectedLeftId = null;
      });
      if (_matchedIds.length == widget.question.pairs.length) {
        Future<void>.delayed(AppMotion.resolve(context, Durations.long2), () {
          if (mounted) {
            widget.onAnswered(
              !_hadMistake,
              widget.question.pairs.map((Flashcard c) => c.id).toList(),
            );
          }
        });
      }
    } else {
      PracticeFeedback.report(context, false, big: false);
      _hadMistake = true;
      setState(() => _flashWrongRightId = rightCard.id);
      Future<void>.delayed(AppMotion.resolve(context, Durations.medium2), () {
        if (mounted) {
          setState(() {
            _flashWrongRightId = null;
            _selectedLeftId = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              children: widget.question.pairs.map((Flashcard card) {
                return _MatchTile(
                  label: card.front,
                  matched: _matchedIds.contains(card.id),
                  selected: _selectedLeftId == card.id,
                  flashWrong: false,
                  onTap: () => _tapLeft(card),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: _rightOrder.map((Flashcard card) {
                return _MatchTile(
                  label: card.back,
                  matched: _matchedIds.contains(card.id),
                  selected: false,
                  flashWrong: _flashWrongRightId == card.id,
                  onTap: () => _tapRight(card),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.label,
    required this.matched,
    required this.selected,
    required this.flashWrong,
    required this.onTap,
  });

  final String label;
  final bool matched;
  final bool selected;
  final bool flashWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Color background = scheme.surfaceContainer;
    Color border = scheme.outlineVariant;
    if (matched) {
      background = scheme.secondaryContainer;
      border = scheme.secondary;
    } else if (flashWrong) {
      background = scheme.errorContainer;
      border = scheme.error;
    } else if (selected) {
      border = scheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedContainer(
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
            onTap: matched ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm + 2,
              ),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
