import 'package:flutter/widgets.dart';
import 'package:komak/core/theme/app_theme.dart';

class ThemeVariantScope extends InheritedWidget {
  const ThemeVariantScope({
    super.key,
    required this.variant,
    required super.child,
  });

  final AppThemeVariant variant;

  static AppThemeVariant of(BuildContext context) {
    final ThemeVariantScope? scope =
        context.dependOnInheritedWidgetOfExactType<ThemeVariantScope>();
    return scope?.variant ?? AppThemeVariant.mocha;
  }

  @override
  bool updateShouldNotify(ThemeVariantScope oldWidget) =>
      oldWidget.variant != variant;
}
