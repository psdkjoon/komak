import 'package:flutter/material.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/models/question_type.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';

Future<void> showPracticeSettingsSheet(BuildContext context, String deckId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) =>
        PracticeSettingsSheet(deckId: deckId),
  );
}

class PracticeSettingsSheet extends StatelessWidget {
  const PracticeSettingsSheet({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final Deck? deck = controller.deckByIdOrNull(deckId);
    final ThemeData theme = Theme.of(context);
    if (deck == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl,),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Practice settings', style: theme.textTheme.titleLarge),
          Text(
            'These only apply to ${deck.title}.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                  child: Text('Questions per practice',
                      style: theme.textTheme.titleSmall,),),
              IconButton.filledTonal(
                tooltip: 'Fewer questions',
                onPressed: deck.practiceLength > minPracticeLength
                    ? () => controller.updateDeck(deck.id,
                        practiceLength: deck.practiceLength - 1,)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 56,
                child: Text('${deck.practiceLength}',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,),
              ),
              IconButton.filledTonal(
                tooltip: 'More questions',
                onPressed: deck.practiceLength < maxPracticeLength
                    ? () => controller.updateDeck(deck.id,
                        practiceLength: deck.practiceLength + 1,)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          Slider(
            value: deck.practiceLength.toDouble(),
            min: minPracticeLength.toDouble(),
            max: maxPracticeLength.toDouble(),
            divisions: maxPracticeLength - minPracticeLength,
            label: '${deck.practiceLength}',
            onChanged: (double value) =>
                controller.updateDeck(deck.id, practiceLength: value.round()),
          ),
          Text(
            deck.cards.length < deck.practiceLength
                ? 'This deck has ${deck.cards.length} cards, so some will come back more than once.'
                : 'Each practice picks ${deck.practiceLength} of ${deck.cards.length} cards, favouring the ones you know least.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Question types', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          for (final QuestionType type in QuestionType.values)
            _TypeSwitch(deck: deck, type: type, controller: controller),
        ],
      ),
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch(
      {required this.deck, required this.type, required this.controller,});

  final Deck deck;
  final QuestionType type;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool available = deck.isTypeAvailable(type);
    final bool enabled = deck.enabledTypes.contains(type);

    final Color tint =
        available ? theme.colorScheme.primary : theme.colorScheme.outline;
    final ValueChanged<bool>? onChanged = available
        ? (bool value) {
            final Set<QuestionType> updated =
                Set<QuestionType>.from(deck.enabledTypes);
            if (value) {
              updated.add(type);
            } else if (updated.length > 1) {
              updated.remove(type);
            }
            controller.setDeckEnabledTypes(deck.id, updated);
          }
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(type.icon, color: tint, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(type.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  available
                      ? type.description
                      : 'Unavailable. ${type.requirement}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(value: enabled && available, onChanged: onChanged),
        ],
      ),
    );
  }
}
