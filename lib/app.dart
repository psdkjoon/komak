import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komak/core/models/app_settings.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/theme/app_theme.dart';
import 'package:komak/core/theme/theme_variant_scope.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/system_sync.dart';
import 'package:komak/features/home/home_screen.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class PsdkKomakApp extends StatelessWidget {
  const PsdkKomakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppSettings settings = controller.settings;
    final Brightness platformBrightness =
        MediaQuery.platformBrightnessOf(context);
    final AppThemeVariant variant = settings.followSystemTheme
        ? (platformBrightness == Brightness.dark
            ? AppThemeVariant.mocha
            : AppThemeVariant.latte)
        : settings.themeVariant;
    final bool isDark = variant == AppThemeVariant.mocha;
    final Color surfaceColor = AppTheme.paletteOf(variant).base;

    final SystemUiOverlayStyle overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: surfaceColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
        title: 'komak',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.build(variant),
        themeAnimationDuration:
            settings.reduceMotion ? Duration.zero : Durations.long4,
        themeAnimationCurve: AppMotion.emphasizedCurve,
        builder: (BuildContext context, Widget? child) {
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          return SystemSync(
            isDark: isDark,
            child: ThemeVariantScope(
              variant: variant,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.textScale),
                ),
                child: child!,
              ),
            ),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
