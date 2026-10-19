import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/localization/localization.dart';
import 'package:komak/theme/app_motion.dart';
import 'package:komak/ui/color_picker_dialog.dart';
import 'package:komak/ui/widgets/pressable_view.dart';

class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
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

  static const double _size = 40;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = color.computeLuminance() > 0.5;
    final mark = light ? const Color(0xFF11111B) : const Color(0xFFFFFFFF);

    return Tooltip(
      message: tooltip ?? '#${colorToHex(color)}',
      child: PressableView(
        playSound: false,
        hoverScale: 1.12,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.quick),
          width: _size,
          height: _size,
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
              ? Icon(icon ?? Icons.check_rounded, size: _iconSize, color: mark)
              : (icon == null
                  ? null
                  : Icon(
                      icon,
                      size: _iconSize,
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
        ),
      ),
    );
  }
}
