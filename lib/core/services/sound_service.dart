import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

enum AppSound {
  tap('Taps', 'Soft click when you press buttons and pick pieces.'),
  correct('Correct answers', 'Chime when you get one right.'),
  wrong('Wrong answers', 'Sound when you miss one.'),
  flip('Card flips', 'Sound when you flip a study card.'),
  success('Practice complete', 'Fanfare at the end of a session.'),
  whoosh('Opening screens', 'Whoosh when a screen opens or the theme changes.');

  const AppSound(this.label, this.description);

  final String label;
  final String description;

  static AppSound? tryParse(String name) {
    for (final AppSound s in AppSound.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

class SoundService {
  static const Map<AppSound, List<String>> _assetPaths =
      <AppSound, List<String>>{
    AppSound.tap: <String>['assets/sounds/tap.wav'],
    AppSound.correct: <String>[
      'assets/sounds/correct_1.wav',
      'assets/sounds/correct_2.wav',
      'assets/sounds/correct_3.wav',
      'assets/sounds/correct_4.wav',
    ],
    AppSound.wrong: <String>[
      'assets/sounds/wrong_1.wav',
      'assets/sounds/wrong_2.wav',
      'assets/sounds/wrong_3.wav',
    ],
    AppSound.flip: <String>['assets/sounds/flip.wav'],
    AppSound.success: <String>['assets/sounds/success.wav'],
    AppSound.whoosh: <String>['assets/sounds/whoosh.wav'],
  };

  static const Map<AppSound, double> _volumes = <AppSound, double>{
    AppSound.tap: 0.35,
    AppSound.correct: 0.7,
    AppSound.wrong: 0.6,
    AppSound.flip: 0.5,
    AppSound.success: 0.8,
    AppSound.whoosh: 0.4,
  };

  final math.Random _random = math.Random();
  final Map<AppSound, List<AudioSource>> _sources =
      <AppSound, List<AudioSource>>{};
  Future<void>? _initFuture;
  bool _broken = false;
  bool enabled = true;
  Set<AppSound> muted = <AppSound>{};

  bool get isBroken => _broken;

  Future<void> _init() async {
    final SoLoud soloud = SoLoud.instance;
    if (!soloud.isInitialized) {
      await soloud.init();
    }
    int loaded = 0;
    for (final MapEntry<AppSound, List<String>> entry in _assetPaths.entries) {
      final List<AudioSource> list = <AudioSource>[];
      for (final String path in entry.value) {
        try {
          list.add(await soloud.loadAsset(path));
          loaded += 1;
        } catch (error) {
          debugPrint('komak: could not load $path: $error');
        }
      }
      _sources[entry.key] = list;
    }
    if (loaded == 0) _broken = true;
  }

  Future<void> play(AppSound sound, {int variant = -1}) async {
    if (!enabled || _broken || muted.contains(sound)) return;
    try {
      _initFuture ??= _init();
      await _initFuture;
      final List<AudioSource>? list = _sources[sound];
      if (list == null || list.isEmpty) return;
      final int index = variant < 0
          ? _random.nextInt(list.length)
          : math.min(variant, list.length - 1);
      await SoLoud.instance.play(list[index], volume: _volumes[sound] ?? 0.6);
    } catch (error) {
      debugPrint('komak: sound error: $error');
      if (_initFuture != null && !SoLoud.instance.isInitialized) _broken = true;
    }
  }

  Future<void> dispose() async {
    try {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.deinit();
      }
    } catch (_) {}
  }
}
