import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.translate = true,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool translate;

  static const double _verticalPadding = 7;
  static const double _gap = 7;
  static const double _iconSize = 15;
  static const double _maxLabelWidth = 160;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: _verticalPadding,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          Icon(icon, size: _iconSize, color: tint),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
              child: translate
                  ? Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(color: tint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text.verbatim(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(color: tint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
