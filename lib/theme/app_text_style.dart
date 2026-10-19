import 'package:flutter/material.dart';
import 'package:komak/localization/localization.dart';

abstract class AppTextStyle {
  static const List<String> fontFallback = [
    'NotoSans',
    'NotoSansArabic',
    'NotoSansJP',
  ];

  static String get fontFamily => switch (L10n.code) {
        'fa' => 'NotoSansArabic',
        'ru' => 'NotoSans',
        'ja' => 'NotoSansJP',
        _ => 'SpaceGrotesk',
      };

  static const double scale = 1.2;

  static TextStyle _style(double size, int weight, {double letterSpacing = 0}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size * scale - 2,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation.weight(weight.toDouble())],
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get displaySmall => _style(30, 600, letterSpacing: -0.4);
  static TextStyle get headlineLarge => _style(26, 600);
  static TextStyle get headlineMedium => _style(22, 600);
  static TextStyle get headlineSmall => _style(22, 600, letterSpacing: -0.4);
  static TextStyle get titleLarge => _style(20, 600);
  static TextStyle get titleMedium => _style(15, 600);
  static TextStyle get titleSmall => _style(14, 500);
  static TextStyle get bodyLarge => _style(16, 400);
  static TextStyle get bodyMedium => _style(14, 400);
  static TextStyle get bodySmall => _style(12, 400);
  static TextStyle get labelLarge => _style(14, 600);
  static TextStyle get labelMedium => _style(12, 600);
  static TextStyle get labelSmall => _style(11, 500);

  static TextTheme get textTheme => TextTheme(
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
