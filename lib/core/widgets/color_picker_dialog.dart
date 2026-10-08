import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komak/core/theme/app_spacing.dart';

Future<Color?> showColorPickerDialog(BuildContext context, Color initial) {
  return showDialog<Color>(
    context: context,
    builder: (BuildContext dialogContext) =>
        _ColorPickerDialog(initial: initial),
  );
}

String colorToHex(Color color) {
  return color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2)
      .toUpperCase();
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});

  final Color initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hexController = TextEditingController(text: colorToHex(widget.initial));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) {
    setState(() => _hsv = value);
    _hexController.text = colorToHex(value.toColor());
  }

  void _onHexChanged(String value) {
    if (value.length != 6) return;
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(0xFF000000 | parsed)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = _hsv.toColor();
    final List<Color> hueColors = <Color>[
      for (int hue = 0; hue <= 360; hue += 60)
        HSVColor.fromAHSV(1, hue.toDouble().clamp(0, 359.9), 1, 1).toColor(),
    ];

    return AlertDialog(
      title: const Text('Custom color'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedContainer(
                duration: Durations.short3,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${colorToHex(color)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color.computeLuminance() > 0.5
                        ? const Color(0xFF11111B)
                        : const Color(0xFFFFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GradientSlider(
                label: 'Hue',
                value: _hsv.hue,
                max: 359.9,
                colors: hueColors,
                onChanged: (double v) => _setHsv(_hsv.withHue(v)),
              ),
              _GradientSlider(
                label: 'Saturation',
                value: _hsv.saturation,
                max: 1,
                colors: <Color>[
                  _hsv.withSaturation(0).toColor(),
                  _hsv.withSaturation(1).toColor(),
                ],
                onChanged: (double v) => _setHsv(_hsv.withSaturation(v)),
              ),
              _GradientSlider(
                label: 'Brightness',
                value: _hsv.value,
                max: 1,
                colors: <Color>[
                  _hsv.withValue(0).toColor(),
                  _hsv.withValue(1).toColor(),
                ],
                onChanged: (double v) => _setHsv(_hsv.withValue(v)),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _hexController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                ],
                onChanged: _onHexChanged,
                decoration: const InputDecoration(
                  labelText: 'Hex',
                  prefixText: '# ',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('Use color'),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              SliderTheme(
                data: theme.sliderTheme.copyWith(
                  trackHeight: 14,
                  activeTrackColor: const Color(0x00000000),
                  inactiveTrackColor: const Color(0x00000000),
                  thumbColor: const Color(0xFFFFFFFF),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 3,
                  ),
                ),
                child: Slider(
                  value: value.clamp(0.0, max),
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
