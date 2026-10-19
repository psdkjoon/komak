import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:komak/app_info.dart';
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_scope.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/settings/app_settings.dart';
import 'package:komak/theme/app_theme.dart';
import 'package:komak/ui/app_shell.dart';

class KomakApp extends StatelessWidget {
  const KomakApp({
    required this.settings,
    required this.controller,
    super.key,
  });

  final AppSettings settings;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return MaterialApp(
            onGenerateTitle: (_) => AppInfo.name.tr,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(settings.accent),
            darkTheme: AppTheme.dark(settings.accent),
            themeMode: settings.themeMode,
            scrollBehavior: const _NoScrollbarBehavior(),
            locale: L10n.locale,
            supportedLocales: [
              for (final language in L10n.languages) Locale(language.code),
            ],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(settings.textScale),
                  disableAnimations:
                      media.disableAnimations || settings.reduceMotion,
                ),
                child: child!,
              );
            },
            home: KeyedSubtree(
              key: ValueKey(L10n.code),
              child: AppShell(settings: settings),
            ),
          );
        },
      ),
    );
  }
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
