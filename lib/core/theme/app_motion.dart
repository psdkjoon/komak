import 'package:flutter/material.dart';
import 'package:komak/core/widgets/app_scope.dart';

abstract class AppMotion {
  static const Duration quick = Durations.short3;
  static const Duration standard = Durations.medium2;
  static const Duration emphasized = Durations.long2;
  static const Duration page = Durations.medium4;
  static const Duration playful = Durations.extralong1;

  static const Curve standardCurve = Easing.standard;
  static const Curve enterCurve = Easing.emphasizedDecelerate;
  static const Curve exitCurve = Easing.emphasizedAccelerate;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

  static bool isReduced(BuildContext context) {
    return AppScope.read(context).settings.reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
  }

  static Duration resolve(BuildContext context, Duration duration) {
    return isReduced(context) ? Duration.zero : duration;
  }
}
