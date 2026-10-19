import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

abstract class SystemService {
  static const _channel = MethodChannel('komak/system');

  static Future<void> openUrl(String url) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('openUrl', {'url': url});
      return;
    }
    if (Platform.isWindows) {
      await Process.start(
        'rundll32',
        ['url.dll,FileProtocolHandler', url],
        mode: ProcessStartMode.detached,
      );
      return;
    }
    await Process.start(
      'xdg-open',
      [url],
      mode: ProcessStartMode.detached,
    );
  }

  static Future<String?> androidAbi() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('abi');
    } on PlatformException {
      return null;
    }
  }

  /// Hands a downloaded APK to Android's installer. Returns `true` when the
  /// install screen was opened, `false` when the user first has to allow
  /// installs from this app (the install continues once they come back).
  static Future<bool> installApk(String path) async {
    final status = await _channel.invokeMethod<String>('installApk', {'path': path});
    return status == 'installing';
  }

  static Future<void> notify(String title, String body) async {
    if (!Platform.isAndroid && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod<void>('notify', {'title': title, 'body': body});
    } on PlatformException {
      return;
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('requestNotifications');
    } on PlatformException {
      return;
    }
  }
}
