import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/theme/app_spacing.dart';

enum OptionState { neutral, selected, disabled, correct, wrong }

class OptionButton extends StatelessWidget {
  const OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
    super.key,
    this.leading,
  });

  static const double _verticalPadding = 12;
  static const double _iconSize = 20;
  static const double _idleBorderWidth = 1;
  static const double _activeBorderWidth = 1.6;

  final String label;
  final OptionState state;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    var background = scheme.surfaceContainer;
    var foreground = scheme.onSurface;
    var border = scheme.outlineVariant;
    IconData? trailing;

    switch (state) {
      case OptionState.neutral:
        break;
      case OptionState.selected:
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
        border = scheme.primary;
        trailing = Icons.check_rounded;
      case OptionState.disabled:
        foreground = scheme.onSurfaceVariant;
      case OptionState.correct:
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        border = scheme.secondary;
        trailing = Icons.check_circle_rounded;
      case OptionState.wrong:
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
        border = scheme.error;
        trailing = Icons.cancel_rounded;
    }

    return AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.standard),
      curve: AppMotion.emphasizedCurve,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(
          color: border,
          width: state == OptionState.neutral
              ? _idleBorderWidth
              : _activeBorderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: _verticalPadding,
            ),
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: leading,
                  ),
                Expanded(
                  child: Text.verbatim(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, color: foreground, size: _iconSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
