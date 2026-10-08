import 'package:flutter/material.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/theme/app_motion.dart';
import 'package:komak/core/widgets/app_scope.dart';

abstract class AppRoutes {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    final Duration duration = AppMotion.resolve(context, AppMotion.page);
    AppScope.read(context).sound.play(AppSound.whoosh);
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
        ) =>
            page,
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<double> enter = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enterCurve,
            reverseCurve: AppMotion.exitCurve,
          );
          return FadeTransition(
            opacity: enter,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                      .animate(enter),
              child: child,
            ),
          );
        },
      ),
    );
  }

  static Future<T?> replace<T, R>(BuildContext context, Widget page) {
    final Duration duration = AppMotion.resolve(context, AppMotion.page);
    return Navigator.of(context).pushReplacement<T, R>(
      PageRouteBuilder<T>(
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
        ) =>
            page,
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<double> enter =
              CurvedAnimation(parent: animation, curve: AppMotion.enterCurve);
          return FadeTransition(opacity: enter, child: child);
        },
      ),
    );
  }
}
