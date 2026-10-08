import 'dart:async';

import 'package:flutter/material.dart';
import 'package:komak/core/constants/deck_icons.dart';
import 'package:komak/core/models/deck.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/theme/catppuccin_palette.dart';
import 'package:komak/core/widgets/app_route.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/color_picker_dialog.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/pressable_scale.dart';
import 'package:komak/core/widgets/sliver_content.dart';
import 'package:komak/features/deck/deck_detail_screen.dart';
import 'package:komak/features/home/widgets/deck_tile.dart';

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

  bool get _isEditing => widget.deckId != null;

  static final List<Color> _presets = <Color>[
    CatppuccinPalette.mocha.rosewater,
    CatppuccinPalette.mocha.flamingo,
    CatppuccinPalette.mocha.pink,
    CatppuccinPalette.mocha.mauve,
    CatppuccinPalette.mocha.red,
    CatppuccinPalette.mocha.maroon,
    CatppuccinPalette.mocha.peach,
    CatppuccinPalette.mocha.yellow,
    CatppuccinPalette.mocha.green,
    CatppuccinPalette.mocha.teal,
    CatppuccinPalette.mocha.sky,
    CatppuccinPalette.mocha.sapphire,
    CatppuccinPalette.mocha.blue,
    CatppuccinPalette.mocha.lavender,
  ];

  @override
  void initState() {
    super.initState();
    final Deck? existing = widget.deckId == null
        ? null
        : AppScope.read(context).deckByIdOrNull(widget.deckId!);
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _accent =
        existing?.accentColorValue ?? CatppuccinPalette.mocha.mauve.toARGB32();
    _iconKey = existing?.iconKey ?? 'style';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isCustomColor =>
      !_presets.any((Color c) => c.toARGB32() == _accent);

  Future<void> _pickCustomColor() async {
    final Color? picked = await showColorPickerDialog(context, Color(_accent));
    if (picked != null) setState(() => _accent = picked.toARGB32());
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) return;
    final AppController controller = AppScope.read(context);

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

    final Deck deck = Deck(
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
    final Deck preview = Deck(
      id: 'preview',
      title: _titleController.text.trim().isEmpty
          ? 'Deck title'
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      accentColorValue: _accent,
      iconKey: _iconKey,
    );
    return SizedBox(
      height: 188,
      child: IgnorePointer(
        child: DeckTile(deck: preview, onTap: () {}, heroEnabled: false),
      ),
    );
  }

  Widget _buildColorSection(ThemeData theme) {
    return SectionCard(
      title: 'Color',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final Color color in _presets)
            _ColorDot(
              color: color,
              selected: color.toARGB32() == _accent,
              onTap: () => setState(() => _accent = color.toARGB32()),
            ),
          _ColorDot(
            color: _isCustomColor
                ? Color(_accent)
                : theme.colorScheme.surfaceContainerHigh,
            selected: _isCustomColor,
            icon: Icons.colorize_rounded,
            onTap: _pickCustomColor,
            tooltip: 'Custom color',
          ),
        ],
      ),
    );
  }

  Widget _buildIconSection(ThemeData theme) {
    final List<DeckIconEntry> icons = searchDeckIcons(_iconQuery);
    final Color accent = Color(_accent);

    return SectionCard(
      title: 'Icon',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            onChanged: (String value) => setState(() => _iconQuery = value),
            decoration: InputDecoration(
              hintText:
                  'Search ${deckIconRegistry.length} icons — try "music", "food" or "math"',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 264,
            child: icons.isEmpty
                ? Center(
                    child: Text(
                      'No icons match "$_iconQuery".',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 56,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DeckIconEntry entry = icons[index];
                      final bool selected = entry.key == _iconKey;
                      return Tooltip(
                        message: entry.label,
                        child: PressableScale(
                          playSound: false,
                          hoverScale: 1.08,
                          onTap: () => setState(() => _iconKey = entry.key),
                          child: AnimatedContainer(
                            duration:
                                AppMotion.resolve(context, AppMotion.quick),
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent.withValues(alpha: 0.24)
                                  : theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: selected ? accent : Colors.transparent,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget basics = SectionCard(
      title: 'Basics',
      child: Column(
        children: <Widget>[
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 48,
            decoration: const InputDecoration(labelText: 'Deck title'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descriptionController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Short description (optional)',
            ),
          ),
        ],
      ),
    );

    final Widget saveButton = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _titleController.text.trim().isEmpty ? null : _save,
        icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
        label: Text(_isEditing ? 'Save changes' : 'Create deck'),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit deck' : 'New deck')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide =
                constraints.maxWidth >= AppLayout.expandedMinWidth;
            final List<Widget> form = <Widget>[
              basics,
              const SizedBox(height: AppSpacing.md),
              _buildColorSection(theme),
              const SizedBox(height: AppSpacing.md),
              _buildIconSection(theme),
              const SizedBox(height: AppSpacing.lg),
              saveButton,
            ];

            if (wide) {
              return ResponsivePage(
                maxWidth: 1000,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: Column(children: form)),
                      const SizedBox(width: AppSpacing.lg),
                      SizedBox(
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Preview',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _buildPreview(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return ResponsivePage(
              children: <Widget>[
                _buildPreview(),
                const SizedBox(height: AppSpacing.md),
                ...form,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
    this.tooltip,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool light = color.computeLuminance() > 0.5;
    final Color mark =
        light ? const Color(0xFF11111B) : const Color(0xFFFFFFFF);

    return Tooltip(
      message: tooltip ?? '#${colorToHex(color)}',
      child: PressableScale(
        playSound: false,
        hoverScale: 1.12,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.quick),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  selected ? theme.colorScheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? Icon(icon ?? Icons.check_rounded, size: 20, color: mark)
              : (icon == null
                  ? null
                  : Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
        ),
      ),
    );
  }
}
