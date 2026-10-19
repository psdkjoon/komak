import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/practice/deck_profile.dart';
import 'package:komak/practice/practice_kind.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/practice_session_screen.dart';
import 'package:komak/ui/widgets/page_frame.dart';

class PracticeMenuScreen extends StatelessWidget {
  const PracticeMenuScreen({super.key, required this.deckId});

  final String deckId;

  static const List<int> _lengths = <int>[10, 20, 30, 50, 100, 200, 500];

  void _open(BuildContext context, PracticeSessionScreen screen) {
    unawaited(AppRoutes.push<void>(context, screen));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final deck = controller.deckByIdOrNull(deckId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (deck == null) return const Scaffold();
    final profile = DeckProfile.of(deck.cards);
    final lengths = <int>{..._lengths, deck.practiceLength}.toList()
      ..sort((int a, int b) => a.compareTo(b));
    lengths
      ..remove(endlessPractice)
      ..add(endlessPractice);

    return Scaffold(
      appBar: AppBar(
        title: Text.verbatim(deck.title, maxLines: 1),
      ),
      body: SafeArea(
        child: PageFrame(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Questions per practice',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final n in lengths)
                    ChoiceChip(
                      label: n == endlessPractice
                          ? const Text('Endless')
                          : Text.verbatim('$n'),
                      selected: deck.practiceLength == n,
                      onSelected: (_) => unawaited(
                        controller.updateDeck(deck.id, practiceLength: n),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Text(
                  'New cards are shown to you first, so every question is one you can answer. Use Learn for the first pass.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              FilledButton.icon(
                onPressed: deck.cards.isEmpty
                    ? null
                    : () => _open(
                          context,
                          PracticeSessionScreen(deckId: deck.id),
                        ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start mixed practice'),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final section in PracticeSection.values)
                _SectionTile(
                  deck: deck,
                  section: section,
                  profile: profile,
                  onToggle: (PracticeKind kind, bool on) {
                    final next = Set<PracticeKind>.of(deck.enabledKinds);
                    if (on) {
                      next.add(kind);
                    } else {
                      next.remove(kind);
                    }
                    unawaited(controller.setDeckEnabledKinds(deck.id, next));
                  },
                  onPlay: (Set<PracticeKind> kinds, PracticeSection? s) =>
                      _open(
                        context,
                        PracticeSessionScreen(
                          deckId: deck.id,
                          kinds: kinds.isEmpty ? null : kinds,
                          section: s,
                        ),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.deck,
    required this.section,
    required this.profile,
    required this.onToggle,
    required this.onPlay,
  });

  final Deck deck;
  final PracticeSection section;
  final DeckProfile profile;
  final void Function(PracticeKind kind, bool on) onToggle;
  final void Function(Set<PracticeKind> kinds, PracticeSection? section)
      onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kinds = section.kinds;
    final ready = kinds.where(profile.supports).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(section.icon, color: deck.accentColor),
          title: Text(section.label),
          subtitle: Text.verbatim(
            '${section.description.tr}  ·  $ready/${kinds.length}',
          ),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
                child: TextButton.icon(
                  onPressed: ready == 0
                      ? null
                      : () => onPlay(const <PracticeKind>{}, section),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Practice this section'),
                ),
              ),
            ),
            for (final kind in kinds)
              _KindRow(
                kind: kind,
                available: profile.supports(kind),
                enabled: deck.enabledKinds.contains(kind),
                onToggle: (bool on) => onToggle(kind, on),
                onPlay: () => onPlay(<PracticeKind>{kind}, null),
              ),
          ],
        ),
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({
    required this.kind,
    required this.available,
    required this.enabled,
    required this.onToggle,
    required this.onPlay,
  });

  final PracticeKind kind;
  final bool available;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      dense: true,
      enabled: available,
      leading: Icon(kind.icon, color: available ? null : scheme.outline),
      title: Text(kind.label),
      subtitle: available
          ? null
          : Text(
              kind.need.description,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: enabled,
            onChanged: available ? onToggle : null,
          ),
          IconButton(
            tooltip: 'Play only this type'.tr,
            onPressed: available ? onPlay : null,
            icon: const Icon(Icons.play_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
