import 'package:flutter/material.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_spacing.dart';

enum OptionState { neutral, disabled, correct, wrong }

class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.leading,
  });

  final String label;
  final OptionState state;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Color background = scheme.surfaceContainer;
    Color foreground = scheme.onSurface;
    Color border = scheme.outlineVariant;
    IconData? trailing;

    switch (state) {
      case OptionState.neutral:
        break;
      case OptionState.disabled:
        foreground = scheme.onSurfaceVariant;
        break;
      case OptionState.correct:
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        border = scheme.secondary;
        trailing = Icons.check_circle_rounded;
        break;
      case OptionState.wrong:
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
        border = scheme.error;
        trailing = Icons.cancel_rounded;
        break;
    }

    return AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.standard),
      curve: AppMotion.emphasizedCurve,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: border,
          width: state == OptionState.neutral ? 1 : 1.6,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, color: foreground, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
