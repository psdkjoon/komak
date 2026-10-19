import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:komak/core/app_dirs.dart';

/// The app watches itself for bugs: every uncaught error, from Flutter, from
/// Dart and from the Android side (see `MainApplication.kt`), is written to
/// `errors.log` in the app's data folder. About > Diagnostics copies it, so a
/// bug report is one tap away instead of "it just closed".
abstract class Diagnostics {
  static const _maxBytes = 64 * 1024;

  static File? _file;

  /// How many errors the log holds. The About screen listens to it.
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static Future<void> init() async {
    try {
      final file = File('${await AppDirs.data()}/errors.log');
      _file = file;
      if (file.existsSync()) count.value = _entries(file.readAsStringSync());
    } on Object {
      _file = null;
    }

    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack, source: 'flutter');
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, source: 'dart');
      return true;
    };
  }

  static void record(Object error, StackTrace? stack, {String source = 'app'}) {
    debugPrint('[$source] $error');
    final file = _file;
    if (file == null) return;
    try {
      final stamp = DateTime.now().toIso8601String();
      final trace = stack == null ? '' : '\n$stack';
      file.writeAsStringSync(
        '--- $stamp [$source]\n$error$trace\n',
        mode: FileMode.append,
        flush: true,
      );
      if (file.lengthSync() > _maxBytes) _trim(file);
      count.value = _entries(file.readAsStringSync());
    } on Object {
      return;
    }
  }

  static String read() {
    final file = _file;
    if (file == null || !file.existsSync()) return '';
    try {
      return file.readAsStringSync();
    } on Object {
      return '';
    }
  }

  static void clear() {
    try {
      _file?.writeAsStringSync('');
    } on Object {
      return;
    }
    count.value = 0;
  }

  static int _entries(String text) => '--- '.allMatches(text).length;

  // Keeps the newest half, starting at an entry boundary.
  static void _trim(File file) {
    final text = file.readAsStringSync();
    final cut = text.indexOf('--- ', text.length ~/ 2);
    file.writeAsStringSync(cut < 0 ? '' : text.substring(cut));
  }
}
