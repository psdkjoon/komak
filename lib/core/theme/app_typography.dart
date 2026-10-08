import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const String primaryFontFamily = 'SpaceGrotesk';

  static const List<String> fallbackFontFamilies = <String>[
    'NotoSansArabic',
    'NotoSansHebrew',
    'NotoSansDevanagari',
    'NotoSansThai',
    'NotoSansSC',
    'NotoSans',
  ];

  static TextTheme buildTextTheme(Color color) {
    final TextStyle base = TextStyle(
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fallbackFontFamilies,
      color: color,
      height: 1.32,
    );

    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 46,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.0,
      ),
      displayMedium: base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      displaySmall: base.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineLarge: base.copyWith(fontSize: 26, fontWeight: FontWeight.w600),
      headlineMedium: base.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: base.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      titleLarge: base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall:
          base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}
