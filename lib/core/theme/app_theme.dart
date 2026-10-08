import 'package:flutter/material.dart';
import 'package:komak/core/theme/app_colors_extension.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/theme/app_typography.dart';
import 'package:komak/core/theme/catppuccin_palette.dart';

enum AppThemeVariant { mocha, latte }

class AppTheme {
  const AppTheme._();

  static CatppuccinPalette paletteOf(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.mocha:
        return CatppuccinPalette.mocha;
      case AppThemeVariant.latte:
        return CatppuccinPalette.latte;
    }
  }

  static ThemeData build(AppThemeVariant variant) {
    final CatppuccinPalette palette = paletteOf(variant);
    final Brightness brightness =
        variant == AppThemeVariant.mocha ? Brightness.dark : Brightness.light;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: palette.mauve,
      onPrimary: palette.crust,
      primaryContainer: palette.mauve.withValues(alpha: 0.2),
      onPrimaryContainer: palette.mauve,
      secondary: palette.teal,
      onSecondary: palette.crust,
      secondaryContainer: palette.teal.withValues(alpha: 0.2),
      onSecondaryContainer: palette.teal,
      tertiary: palette.peach,
      onTertiary: palette.crust,
      tertiaryContainer: palette.peach.withValues(alpha: 0.2),
      onTertiaryContainer: palette.peach,
      error: palette.red,
      onError: palette.crust,
      errorContainer: palette.red.withValues(alpha: 0.18),
      onErrorContainer: palette.red,
      surface: palette.base,
      onSurface: palette.text,
      onSurfaceVariant: palette.subtext0,
      surfaceContainerLowest: palette.crust,
      surfaceContainerLow: palette.mantle,
      surfaceContainer: palette.surface0,
      surfaceContainerHigh: palette.surface1,
      surfaceContainerHighest: palette.surface2,
      outline: palette.overlay0,
      outlineVariant: palette.surface1,
      shadow: palette.crust,
      inverseSurface: palette.text,
      onInverseSurface: palette.base,
      inversePrimary: palette.blue,
    );

    final TextTheme textTheme = AppTypography.buildTextTheme(palette.text);

    final AppColorsExtension colors = AppColorsExtension(
      success: palette.green,
      onSuccess: palette.crust,
      warning: palette.yellow,
      info: palette.sapphire,
      streak: palette.peach,
    );

    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.base,
      canvasColor: palette.base,
      fontFamily: AppTypography.primaryFontFamily,
      fontFamilyFallback: AppTypography.fallbackFontFamilies,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.base,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.surface0,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme:
          DividerThemeData(color: palette.surface1, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface1,
        selectedColor: palette.mauve.withValues(alpha: 0.24),
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
          minimumSize: const Size(0, 48),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.mauve,
          foregroundColor: palette.crust,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.surface2),
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.mauve,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.surface2),
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.surface1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.mauve, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.overlay1),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.subtext0),
        helperStyle: textTheme.bodySmall?.copyWith(color: palette.subtext0),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.mantle,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.mantle,
        showDragHandle: true,
        dragHandleColor: palette.surface2,
        constraints: const BoxConstraints(maxWidth: AppLayout.readableMaxWidth),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface1,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: textTheme.labelMedium,
        waitDuration: Durations.long2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface1,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: palette.mauve,
        behavior: SnackBarBehavior.floating,
        width: 420,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.crust
              : palette.overlay1,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.mauve
              : palette.surface1,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.mauve,
        inactiveTrackColor: palette.surface1,
        thumbColor: palette.mauve,
        overlayColor: palette.mauve.withValues(alpha: 0.16),
        trackHeight: 6,
        valueIndicatorColor: palette.surface2,
        valueIndicatorTextStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.mauve,
        linearTrackColor: palette.surface1,
        circularTrackColor: palette.surface1,
        linearMinHeight: 8,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.subtext0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(palette.surface2),
        radius: const Radius.circular(AppRadius.pill),
        thickness: WidgetStateProperty.all(6),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _FadeScaleTransitionsBuilder(),
          TargetPlatform.linux: _FadeScaleTransitionsBuilder(),
          TargetPlatform.windows: _FadeScaleTransitionsBuilder(),
          TargetPlatform.macOS: _FadeScaleTransitionsBuilder(),
          TargetPlatform.iOS: _FadeScaleTransitionsBuilder(),
        },
      ),
    );
  }
}

class _FadeScaleTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeScaleTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> enter =
        CurvedAnimation(parent: animation, curve: Easing.emphasizedDecelerate);
    final Animation<double> exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Easing.emphasizedAccelerate,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(exit),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(enter),
        child: FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}
