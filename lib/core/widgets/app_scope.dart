import 'package:flutter/widgets.dart';
import 'package:komak/core/services/app_controller.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called outside of an AppScope.');
    return scope!.notifier!;
  }

  static AppController read(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.read() called outside of an AppScope.');
    return scope!.notifier!;
  }
}
