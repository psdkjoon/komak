import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppIconService {
  static const MethodChannel _channel =
      MethodChannel('ir.psdkjoon.komak/app_icon');

  static bool? _lastDark;

  static Future<void> apply({required bool dark}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_lastDark == dark) return;
    _lastDark = dark;
    try {
      await _channel
          .invokeMethod<void>('setPendingIcon', <String, Object>{'dark': dark});
    } catch (error) {
      debugPrint('komak: could not store app icon choice: $error');
    }
  }
}
