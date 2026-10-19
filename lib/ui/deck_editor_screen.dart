import 'dart:async';

import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck.dart';
import 'package:komak/decks/deck_colors.dart';
import 'package:komak/decks/deck_icons.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/app_route.dart';
import 'package:komak/ui/color_picker_dialog.dart';
import 'package:komak/ui/deck_detail_screen.dart';
import 'package:komak/ui/widgets/color_dot.dart';
import 'package:komak/ui/widgets/deck_tile.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/pressable_view.dart';
import 'package:komak/ui/widgets/settings_section.dart';

class DeckEditorScreen extends StatefulWidget {
  const DeckEditorScreen({super.key, this.deckId});

  final String? deckId;

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _accent;
  late String _iconKey;
  String _iconQuery = '';

  static const double _previewHeight = 132;
  static const double _iconGridHeight = 264;
  static const double _iconMaxExtent = 56;
  static const double _iconHoverScale = 1.08;
  static const int _titleMaxLength = 48;

  bool get _isEditing => widget.deckId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.deckId == null
        ? null
        : AppScope.read(context).deckByIdOrNull(widget.deckId!);
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _accent =
        existing?.accentColorValue ?? DeckColors.fallback.toARGB32();
    _iconKey = existing?.iconKey ?? 'style';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isCustomColor => !DeckColors.isPreset(_accent);

  Future<void> _pickCustomColor() async {
    final picked = await showColorPickerDialog(context, Color(_accent));
    if (picked != null) setState(() => _accent = picked.toARGB32());
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final controller = AppScope.read(context);

    if (_isEditing) {
      await controller.updateDeck(
        widget.deckId!,
        title: title,
        description: _descriptionController.text.trim(),
        accentColorValue: _accent,
        iconKey: _iconKey,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final deck = Deck(
      title: title,
      description: _descriptionController.text.trim(),
      accentColorValue: _accent,
      iconKey: _iconKey,
    );
    await controller.addDeck(deck);
    if (!mounted) return;
    unawaited(
      AppRoutes.replace<void, void>(
        context,
        DeckDetailScreen(deckId: deck.id),
      ),
    );
  }

  Widget _buildPreview() {
    final preview = Deck(
      id: 'preview',
      title: _titleController.text.trim().isEmpty
          ? 'Deck title'.tr
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      accentColorValue: _accent,
      iconKey: _iconKey,
    );
    return SizedBox(
      height: _previewHeight,
      child: IgnorePointer(
        child: DeckTile(deck: preview, onTap: () {}, heroEnabled: false),
      ),
    );
  }

  Widget _buildBasicsSection() {
    return SettingsSection(
      title: 'Basics',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            spacing: AppSpacing.sm,
            children: [
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                maxLength: _titleMaxLength,
                decoration: InputDecoration(labelText: 'Deck title'.tr),
              ),
              TextField(
                controller: _descriptionController,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Short description (optional)'.tr,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection(ThemeData theme) {
    return SettingsSection(
      title: 'Color',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final color in DeckColors.presets)
                ColorDot(
                  color: color,
                  selected: color.toARGB32() == _accent,
                  onTap: () => setState(() => _accent = color.toARGB32()),
                ),
              ColorDot(
                color: _isCustomColor
                    ? Color(_accent)
                    : theme.colorScheme.surfaceContainerHigh,
                selected: _isCustomColor,
                icon: Icons.colorize_rounded,
                onTap: _pickCustomColor,
                tooltip: 'Custom color'.tr,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconSection(ThemeData theme) {
    final icons = searchDeckIcons(_iconQuery);
    final accent = Color(_accent);

    return SettingsSection(
      title: 'Icon',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            spacing: AppSpacing.sm,
            children: [
              TextField(
                onChanged: (value) => setState(() => _iconQuery = value),
                decoration: InputDecoration(
                  hintText: L10n.fmt(
                    'Search {} icons — try "music", "food" or "math"',
                    <Object?>[deckIconRegistry.length],
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              SizedBox(
                height: _iconGridHeight,
                child: icons.isEmpty
                    ? Center(
                        child: Text.verbatim(
                          L10n.fmt(
                            'No icons match "{}".',
                            <Object?>[_iconQuery],
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: _iconMaxExtent,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                        ),
                        itemCount: icons.length,
                        itemBuilder: (context, index) {
                          final entry = icons[index];
                          final selected = entry.key == _iconKey;
                          return Tooltip(
                            message: entry.label,
                            child: PressableView(
                              playSound: false,
                              hoverScale: _iconHoverScale,
                              onTap: () =>
                                  setState(() => _iconKey = entry.key),
                              child: AnimatedContainer(
                                duration: AppMotion.resolve(
                                  context,
                                  AppMotion.quick,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accent.withValues(alpha: 0.24)
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.tile),
                                  border: Border.all(
                                    color:
                                        selected ? accent : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  entry.icon,
                                  color: selected
                                      ? accent
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit deck' : 'New deck')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                _buildPreview(),
                _buildBasicsSection(),
                _buildColorSection(theme),
                _buildIconSection(theme),
                FilledButton.icon(
                  onPressed: _titleController.text.trim().isEmpty ? null : _save,
                  icon: Icon(
                    _isEditing ? Icons.check_rounded : Icons.add_rounded,
                  ),
                  label: Text(_isEditing ? 'Save changes' : 'Create deck'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
