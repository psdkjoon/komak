import 'package:flutter/material.dart';
import 'package:komak/core/theme/app_spacing.dart';

class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            text,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
