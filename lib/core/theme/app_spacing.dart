abstract class AppSpacing {
  static const double spaceUnit = 16;

  static const double xxs = 0.25 * spaceUnit;
  static const double xs = 0.5 * spaceUnit;
  static const double sm = 0.75 * spaceUnit;
  static const double md = spaceUnit;
  static const double lg = 1.5 * spaceUnit;
  static const double xl = 2 * spaceUnit;
  static const double xxl = 3 * spaceUnit;
}

abstract class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

abstract class AppLayout {
  static const double compactMaxWidth = 600;
  static const double expandedMinWidth = 900;
  static const double contentMaxWidth = 1120;
  static const double readableMaxWidth = 640;
  static const double sessionMaxWidth = 620;
  static const double sidePanelWidth = 340;

  static double gutterFor(double viewportWidth, double maxContentWidth) {
    final double centered = (viewportWidth - maxContentWidth) / 2;
    return centered > AppSpacing.lg ? centered : AppSpacing.lg;
  }
}
