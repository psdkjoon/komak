import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:komak/settings/app_settings.dart';

/// Keeps the accent color and the theme (Auto, Latte, Mocha) the same in every app
/// made from this template on one phone (Android only). The newest choice wins.
///
/// - When the user changes the accent or theme here, Android tells the other apps.
/// - Each app asks the others for their look when it starts, when it comes back to
///   the foreground, and when one of them says it changed.
/// - The newest look is also kept by Android in a small file, so an app that was
///   closed when the change happened still opens with it (see [adoptStored]).
///
/// `ThemeSync.kt` does the talking between apps. This class only connects it to
/// [AppSettings].
abstract class ThemeSyncService {
  static const _channel = MethodChannel('komak/theme_sync');
  static AppSettings? _settings;
  static Future<void> _queue = Future.value();
  static String? _sent;
  static bool _wasEnabled = false;

  /// Takes the look Android already holds for this app, before the first frame.
  /// Call it before `runApp`. It does not talk to the other apps, so it is fast.
  static Future<void> adoptStored(AppSettings settings) async {
    if (!Platform.isAndroid || !settings.syncAppearance) return;
    try {
      final state = await _channel.invokeMapMethod<String, Object?>('current');
      _adopt(settings, state);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> init(AppSettings settings) {
    if (!Platform.isAndroid || _settings != null) return Future.value();
    _settings = settings;
    _wasEnabled = settings.syncAppearance;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'refresh') await _run(pull: true);
      return null;
    });
    settings.addListener(_onSettings);
    // Apps that were stopped or frozen miss the "changed" message, so ask again
    // whenever the user comes back.
    WidgetsBinding.instance.addObserver(_ResumeObserver());
    return _run(pull: true);
  }

  static String _key(AppSettings s) =>
      '${s.syncAppearance}|${s.accent}|${s.themeMode.name}|${s.appearanceUpdatedAt}';

  static void _onSettings() {
    final settings = _settings;
    if (settings == null) return;
    final key = _key(settings);
    if (key == _sent) return;
    final turnedOn = settings.syncAppearance && !_wasEnabled;
    _wasEnabled = settings.syncAppearance;
    unawaited(_run(pull: turnedOn));
  }

  // One call at a time, in order.
  static Future<void> _run({required bool pull}) {
    return _queue = _queue.then((_) => _sync(pull: pull));
  }

  static Future<void> _sync({required bool pull}) async {
    final settings = _settings;
    if (settings == null) return;
    try {
      _sent = _key(settings);
      var state = await _channel.invokeMapMethod<String, Object?>('publish', {
        'enabled': settings.syncAppearance,
        'accent': settings.accent,
        'mode': settings.themeMode.name,
        'updatedAt': settings.appearanceUpdatedAt,
      });
      // Apply what we already know first, then ask the other apps.
      var changed = _adopt(settings, state);
      if (pull && settings.syncAppearance) {
        state = await _channel.invokeMapMethod<String, Object?>('pull') ?? state;
        changed = _adopt(settings, state) || changed;
      }
      // Android may stop this process right after a background refresh, so do not
      // leave the new look waiting in memory.
      if (changed) await settings.flush();
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  /// Returns true when [state] was newer than what the settings held.
  static bool _adopt(AppSettings settings, Map<String, Object?>? state) {
    if (state == null || !settings.syncAppearance) return false;
    final accent = state['accent'];
    final updatedAt = state['updatedAt'];
    if (accent is! String || updatedAt is! num) return false;
    final mode = state['mode'];
    if (updatedAt.toInt() <= settings.appearanceUpdatedAt) return false;
    settings.adoptAppearance(
      accent,
      mode is String ? mode : null,
      updatedAt.toInt(),
    );
    return true;
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ThemeSyncService._run(pull: true));
    }
  }
}
