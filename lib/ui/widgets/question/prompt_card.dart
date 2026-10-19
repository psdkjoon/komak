import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';

class PromptCard extends StatelessWidget {
  const PromptCard({required this.text, super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Text.verbatim(
            text,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
