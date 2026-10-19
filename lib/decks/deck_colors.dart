import 'package:komak/theme/catppuccin.dart';

abstract class DeckColors {
  static const _palette = CatppuccinPalette.mocha;

  static final presets = [
    _palette.rosewater,
    _palette.flamingo,
    _palette.pink,
    _palette.mauve,
    _palette.red,
    _palette.maroon,
    _palette.peach,
    _palette.yellow,
    _palette.green,
    _palette.teal,
    _palette.sky,
    _palette.sapphire,
    _palette.blue,
    _palette.lavender,
  ];

  static final fallback = _palette.mauve;

  static bool isPreset(int value) =>
      presets.any((color) => color.toARGB32() == value);
}
