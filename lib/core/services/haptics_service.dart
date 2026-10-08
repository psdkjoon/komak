import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticsService {
  bool enabled = true;

  Future<void> wrong() async {
    if (!enabled) return;
    try {
      final bool hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: <int>[0, 70, 60, 150]);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
