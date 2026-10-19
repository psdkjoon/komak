import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:komak/core/app_dirs.dart';

class KvStore {
  KvStore._(this._file, this._values);

  final File _file;
  final Map<String, Object?> _values;
  Timer? _flush;
  Future<void> _writing = Future.value();

  static Future<KvStore> open() async {
    final file = File('${await AppDirs.data()}/prefs.json');
    var values = <String, Object?>{};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) values = Map<String, Object?>.from(decoded);
      }
    } on Object {
      values = <String, Object?>{};
    }
    return KvStore._(file, values);
  }

  // A hand-edited or damaged file must not crash the app at start, so a value of
  // the wrong type reads as missing.
  String? getString(String key) {
    final value = _values[key];
    return value is String ? value : null;
  }

  int? getInt(String key) {
    final value = _values[key];
    return value is num ? value.toInt() : null;
  }

  bool? getBool(String key) {
    final value = _values[key];
    return value is bool ? value : null;
  }

  List<String>? getStringList(String key) {
    final value = _values[key];
    return value is List ? value.whereType<String>().toList() : null;
  }

  void setString(String key, String value) => _put(key, value);
  void setInt(String key, int value) => _put(key, value);
  void setBool(String key, bool value) => _put(key, value);
  void setStringList(String key, List<String> value) => _put(key, value);
  void remove(String key) => _put(key, null);

  /// Writes pending changes now and completes when they are on disk. Use it when the
  /// process may be stopped right after a change (a background broadcast).
  Future<void> flush() {
    if (_flush?.isActive ?? false) {
      _flush!.cancel();
      _write();
    }
    return _writing;
  }

  void _put(String key, Object? value) {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    _flush?.cancel();
    _flush = Timer(const Duration(milliseconds: 150), _write);
  }

  void _write() {
    final snapshot = jsonEncode(_values);
    _writing = _writing.then((_) async {
      try {
        final temp = File('${_file.path}.tmp');
        await temp.writeAsString(snapshot, flush: true);
        await temp.rename(_file.path);
      } on Object {
        return;
      }
    });
  }
}
