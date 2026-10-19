import 'package:flutter/services.dart';
import 'package:komak/settings/app_settings.dart';

abstract class HapticsService {
  static AppSettings? _settings;

  static void init(AppSettings settings) => _settings = settings;

  static Future<void> select() => _run(HapticFeedback.selectionClick);

  static Future<void> wrong() => _run(HapticFeedback.heavyImpact);

  static Future<void> _run(Future<void> Function() feedback) async {
    if (!(_settings?.hapticsEnabled ?? false)) return;
    try {
      await feedback();
    } on Object {
      return;
    }
  }
}
