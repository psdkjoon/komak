import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_spacing.dart';

class GroupChoice {
  const GroupChoice(this.group);

  final String? group;
}

Future<GroupChoice?> showGroupDialog(
  BuildContext context,
  List<String> existing,
) {
  return showDialog<GroupChoice>(
    context: context,
    builder: (dialogContext) => _GroupDialog(existing: existing),
  );
}

class _GroupDialog extends StatefulWidget {
  const _GroupDialog({required this.existing});

  final List<String> existing;

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move to group'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: 'Group label'.tr),
            ),
            if (widget.existing.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final group in widget.existing)
                    ActionChip(
                      label: Text.verbatim(group),
                      onPressed: () => setState(() => _controller.text = group),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(const GroupChoice(null)),
          child: const Text('Remove group'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context)
                  .pop(GroupChoice(_controller.text.trim())),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
