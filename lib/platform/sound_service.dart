import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:komak/settings/app_settings.dart';

enum AppSound {
  tap('Taps', 'Soft click when you press buttons and pick pieces.'),
  correct('Correct answers', 'Chime when you get one right.'),
  wrong('Wrong answers', 'Sound when you miss one.'),
  flip('Card flips', 'Sound when you flip a study card.'),
  success('Practice complete', 'Fanfare at the end of a session.');

  const AppSound(this.label, this.description);

  final String label;
  final String description;

  static AppSound? tryParse(String name) {
    for (final sound in AppSound.values) {
      if (sound.name == name) return sound;
    }
    return null;
  }
}

abstract class SoundService {
  static const _channel = MethodChannel('komak/sound');

  static const _assets = <AppSound, List<String>>{
    AppSound.tap: ['assets/sounds/tap.wav'],
    AppSound.correct: [
      'assets/sounds/correct_1.wav',
      'assets/sounds/correct_2.wav',
      'assets/sounds/correct_3.wav',
      'assets/sounds/correct_4.wav',
    ],
    AppSound.wrong: [
      'assets/sounds/wrong_1.wav',
      'assets/sounds/wrong_2.wav',
      'assets/sounds/wrong_3.wav',
    ],
    AppSound.flip: ['assets/sounds/flip.wav'],
    AppSound.success: ['assets/sounds/success.wav'],
  };

  static const _volumes = <AppSound, double>{
    AppSound.tap: 0.35,
    AppSound.correct: 0.7,
    AppSound.wrong: 0.6,
    AppSound.flip: 0.5,
    AppSound.success: 0.8,
  };

  static final _random = math.Random();
  static final _handles = <AppSound, List<int>>{};
  static AppSettings? _settings;
  static Future<void>? _loading;
  static List<String>? _desktopPlayer;
  static Process? _windowsShell;
  static bool _broken = false;

  static bool get isBroken => _broken;

  static void init(AppSettings settings) => _settings = settings;

  static Future<void> play(AppSound sound, {int variant = -1}) async {
    final settings = _settings;
    if (settings == null || !settings.soundEnabled || _broken) return;
    if (settings.mutedSounds.contains(sound)) return;
    final files = _assets[sound];
    if (files == null || files.isEmpty) return;
    final index = variant < 0
        ? _random.nextInt(files.length)
        : math.min(variant, files.length - 1);
    final volume = _volumes[sound] ?? 0.6;
    try {
      if (Platform.isAndroid) {
        await (_loading ??= _loadAndroid());
        final handles = _handles[sound];
        if (handles == null || handles.length <= index) return;
        await _channel.invokeMethod<void>('play', {
          'id': handles[index],
          'volume': volume,
        });
      } else if (Platform.isLinux) {
        await _playLinux(files[index], volume);
      } else if (Platform.isWindows) {
        await _playWindows(files[index]);
      }
    } on Object {
      debugPrint('sound unavailable');
      _broken = true;
    }
  }

  static Future<void> _loadAndroid() async {
    var loaded = 0;
    for (final entry in _assets.entries) {
      final handles = <int>[];
      for (final asset in entry.value) {
        final id = await _channel.invokeMethod<int>('load', {'asset': asset});
        handles.add(id ?? 0);
        if ((id ?? 0) > 0) loaded++;
      }
      _handles[entry.key] = handles;
    }
    if (loaded == 0) _broken = true;
  }

  static String _desktopPath(String asset) {
    final separator = Platform.pathSeparator;
    final root = File(Platform.resolvedExecutable).parent.path;
    return [root, 'data', 'flutter_assets', ...asset.split('/')].join(separator);
  }

  static Future<void> _playLinux(String asset, double volume) async {
    final player = _desktopPlayer ??= await _findLinuxPlayer();
    if (player.isEmpty) {
      _broken = true;
      return;
    }
    final command = player.first;
    final path = _desktopPath(asset);
    final args = switch (command) {
      'pw-play' => ['--volume=$volume', path],
      'paplay' => ['--volume=${(volume * 65536).round()}', path],
      _ => ['-q', path],
    };
    await Process.start(command, args, mode: ProcessStartMode.detached);
  }

  static Future<List<String>> _findLinuxPlayer() async {
    for (final command in const ['pw-play', 'paplay', 'aplay']) {
      final result = await Process.run('sh', ['-c', 'command -v $command']);
      if (result.exitCode == 0) return [command];
    }
    return const [];
  }

  static Future<void> _playWindows(String asset) async {
    final shell = _windowsShell ??= await Process.start('powershell', [
      '-NoProfile',
      '-NoLogo',
      '-NonInteractive',
      '-Command',
      '-',
    ]);
    final path = _desktopPath(asset).replaceAll("'", "''");
    shell.stdin.writeln("(New-Object Media.SoundPlayer '$path').PlaySync()");
  }
}
