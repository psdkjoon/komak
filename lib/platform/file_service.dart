import 'dart:io';

import 'package:flutter/services.dart';

abstract class FileService {
  static const _channel = MethodChannel('komak/files');

  static Future<String?> pick(List<String> extensions) async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod<String>('pick', {
          'types': ['*/*'],
        });
      }
      if (Platform.isWindows) return await _pickWindows(extensions);
      return await _pickLinux(extensions);
    } on PlatformException {
      return null;
    } on ProcessException {
      return null;
    }
  }

  static Future<bool> saveToDownloads(String name, List<int> bytes) async {
    if (!Platform.isAndroid) return false;
    try {
      final saved = await _channel.invokeMethod<bool>('saveToDownloads', {
        'name': name,
        'bytes': Uint8List.fromList(bytes),
      });
      return saved ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<String?> _pickLinux(List<String> extensions) async {
    final patterns = [for (final extension in extensions) '*.$extension'];
    final attempts = [
      (
        'zenity',
        ['--file-selection', '--file-filter=${patterns.join(' ')}'],
      ),
      ('kdialog', ['--getopenfilename', '.', patterns.join(' ')]),
    ];
    for (final (command, args) in attempts) {
      try {
        final result = await Process.run(command, args);
        if (result.exitCode != 0) return null;
        final path = '${result.stdout}'.trim();
        return path.isEmpty ? null : path;
      } on ProcessException {
        continue;
      }
    }
    return null;
  }

  static Future<String?> _pickWindows(List<String> extensions) async {
    final filter = extensions.map((extension) => '*.$extension').join(';');
    final script = 'Add-Type -AssemblyName System.Windows.Forms;'
        r'$d = New-Object System.Windows.Forms.OpenFileDialog;'
        "\$d.Filter = 'Decks|$filter';"
        r'if ($d.ShowDialog() -eq "OK") { Write-Output $d.FileName }';
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-STA', '-Command', script],
    );
    final path = '${result.stdout}'.trim();
    return path.isEmpty ? null : path;
  }
}
