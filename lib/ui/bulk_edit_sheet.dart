import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/app_scope.dart';
import 'package:komak/decks/deck_colors.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/color_picker_dialog.dart';
import 'package:komak/ui/widgets/color_dot.dart';

Future<bool> showBulkEditSheet(BuildContext context, Set<String> deckIds) async {
  final applied = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _BulkEditSheet(deckIds: deckIds),
  );
  return applied ?? false;
}

class _BulkEditSheet extends StatefulWidget {
  const _BulkEditSheet({required this.deckIds});

  final Set<String> deckIds;

  @override
  State<_BulkEditSheet> createState() => _BulkEditSheetState();
}

class _BulkEditSheetState extends State<_BulkEditSheet> {
  int? _color;

  bool get _isCustom => _color != null && !DeckColors.isPreset(_color!);

  Future<void> _pickCustom() async {
    final picked = await showColorPickerDialog(
      context,
      Color(_color ?? DeckColors.fallback.toARGB32()),
    );
    if (picked != null) setState(() => _color = picked.toARGB32());
  }

  Future<void> _apply() async {
    final color = _color;
    if (color == null) return;
    final controller = AppScope.read(context);
    final navigator = Navigator.of(context);
    await controller.setDecksColor(widget.deckIds, color);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxs,
            children: [
              Text(
                'Edit ${widget.deckIds.length} decks',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                'Pick a new color for all selected decks.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final color in DeckColors.presets)
                ColorDot(
                  color: color,
                  selected: _color == color.toARGB32(),
                  onTap: () => setState(() => _color = color.toARGB32()),
                ),
              ColorDot(
                color: _isCustom
                    ? Color(_color!)
                    : scheme.surfaceContainerHigh,
                selected: _isCustom,
                icon: Icons.colorize_rounded,
                tooltip: 'Custom color'.tr,
                onTap: _pickCustom,
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: _color == null ? null : _apply,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Apply color'),
          ),
        ],
      ),
    );
  }
}
