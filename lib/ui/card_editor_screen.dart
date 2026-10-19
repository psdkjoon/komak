import 'package:flutter/material.dart' hide Icon, Text;
import 'package:flutter/services.dart';
import 'package:komak/core/card_intake.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/flashcard.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/settings_section.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.deckId, this.existingCard});

  final String deckId;
  final Flashcard? existingCard;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  late final TextEditingController _frontController;
  late final TextEditingController _readingController;
  late final TextEditingController _backController;
  late final TextEditingController _exampleController;
  late final TextEditingController _noteController;
  late final TextEditingController _orderController;
  late final TextEditingController _groupController;
  final _frontFocus = FocusNode();

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    final card = widget.existingCard;
    _frontController = TextEditingController(text: card?.front ?? '');
    _readingController = TextEditingController(text: card?.reading ?? '');
    _backController = TextEditingController(text: card?.back ?? '');
    _exampleController = TextEditingController(text: card?.example ?? '');
    _noteController = TextEditingController(text: card?.note ?? '');
    _orderController =
        TextEditingController(text: card?.orderIndex?.toString() ?? '');
    _groupController = TextEditingController(text: card?.groupId ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _readingController.dispose();
    _backController.dispose();
    _exampleController.dispose();
    _noteController.dispose();
    _orderController.dispose();
    _groupController.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Flashcard _build() {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    final existing = widget.existingCard;
    if (existing == null) {
      return Flashcard(
        front: front,
        back: back,
        reading: _clean(_readingController),
        example: _clean(_exampleController),
        note: _clean(_noteController),
        orderIndex: int.tryParse(_orderController.text.trim()),
        groupId: _clean(_groupController),
      );
    }
    return existing.copyWith(
      front: front,
      back: back,
      reading: _clean(_readingController),
      example: _clean(_exampleController),
      note: _clean(_noteController),
      orderIndex: int.tryParse(_orderController.text.trim()),
      groupId: _clean(_groupController),
      clearReading: _clean(_readingController) == null,
      clearExample: _clean(_exampleController) == null,
      clearNote: _clean(_noteController) == null,
      clearOrder: int.tryParse(_orderController.text.trim()) == null,
      clearGroup: _clean(_groupController) == null,
    );
  }

  bool get _canSave =>
      _frontController.text.trim().isNotEmpty &&
      _backController.text.trim().isNotEmpty;

  bool get _isDuplicate {
    if (!_canSave) return false;
    return AppScope.read(context).isDuplicateCard(widget.deckId, _build());
  }

  Future<void> _save({bool addAnother = false}) async {
    if (!_canSave || _isDuplicate) return;
    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final card = _build();

    if (_isEditing) {
      await controller.updateCard(widget.deckId, card);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final intake = await controller.addCardsToDeck(widget.deckId, [card]);
    if (!mounted) return;
    if (intake.accepted.isEmpty) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text.verbatim(
              L10n.fmt('This deck is full ({} cards max)', [maxCardsPerDeck]),
            ),
          ),
        );
      return;
    }
    if (addAnother) {
      _frontController.clear();
      _readingController.clear();
      _backController.clear();
      _exampleController.clear();
      _noteController.clear();
      _orderController.clear();
      setState(() {});
      _frontFocus.requestFocus();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Card added')));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deck = AppScope.of(context).deckByIdOrNull(widget.deckId);
    final groups = deck?.groups ?? const <String>[];
    final duplicate = _isDuplicate;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit card' : 'New card')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                SettingsSection(
                  title: 'Basics',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        spacing: AppSpacing.sm,
                        children: [
                          TextField(
                            controller: _frontController,
                            focusNode: _frontFocus,
                            autofocus: !_isEditing,
                            maxLines: 3,
                            minLines: 1,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Front (name)'.tr,
                              errorText: duplicate
                                  ? 'This card already exists in the deck.'.tr
                                  : null,
                            ),
                          ),
                          TextField(
                            controller: _readingController,
                            decoration: InputDecoration(
                              labelText: 'Reading (pronunciation)'.tr,
                            ),
                          ),
                          TextField(
                            controller: _backController,
                            maxLines: 3,
                            minLines: 1,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Back (meaning)'.tr,
                              errorText: duplicate
                                  ? 'This card already exists in the deck.'.tr
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Help me remember',
                  help:
                      'Examples and memory tricks make a card easier to learn. They are shown when you learn the card, after you flip it.',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        spacing: AppSpacing.sm,
                        children: [
                          TextField(
                            controller: _exampleController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              labelText: 'Example sentence'.tr,
                            ),
                          ),
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              labelText: 'Note or memory trick'.tr,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Organise',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.sm,
                        children: [
                          TextField(
                            controller: _groupController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Group label'.tr,
                              helperText:
                                  'Shared across cards, unlocks the Odd One Out type.'
                                      .tr,
                            ),
                          ),
                          if (groups.isNotEmpty)
                            Wrap(
                              spacing: AppSpacing.xxs,
                              runSpacing: AppSpacing.xxs,
                              children: [
                                for (final group in groups)
                                  ChoiceChip(
                                    label: Text.verbatim(group),
                                    selected:
                                        _groupController.text.trim() == group,
                                    onSelected: (_) => setState(
                                      () => _groupController.text = group,
                                    ),
                                  ),
                              ],
                            ),
                          TextField(
                            controller: _orderController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Order position'.tr,
                              helperText:
                                  'Fill this in on 3+ cards to unlock the Correct Order type.'
                                      .tr,
                            ),
                          ),
                          if (deck != null)
                            Text.verbatim(
                              L10n.fmt(
                                '{} of {} cards in this deck',
                                [deck.cards.length, maxCardsPerDeck],
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _canSave && !duplicate ? _save : null,
                  icon: Icon(
                    _isEditing ? Icons.check_rounded : Icons.add_rounded,
                  ),
                  label: Text(_isEditing ? 'Save changes' : 'Add card'),
                ),
                if (!_isEditing)
                  OutlinedButton.icon(
                    onPressed: _canSave && !duplicate
                        ? () => _save(addAnother: true)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add and add another'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
