import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komak/app.dart';
import 'package:komak/core/diagnostics.dart';
import 'package:komak/core/kv_store.dart';
import 'package:komak/decks/app_controller.dart';
import 'package:komak/decks/app_store.dart';
import 'package:komak/platform/haptics_service.dart';
import 'package:komak/platform/launcher_icon_service.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/platform/theme_sync_service.dart';
import 'package:komak/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Diagnostics.init();

  final store = await KvStore.open();
  final settings = AppSettings.load(store);
  final controller = AppController(AppStore(store), settings);
  await controller.initialize();

  // A sibling app may have changed the look while this app was closed. Take it before
  // the first frame, so the UI never opens in the old accent or theme.
  await ThemeSyncService.adoptStored(settings);

  runApp(KomakApp(settings: settings, controller: controller));

  unawaited(_initPlatform(settings));
}

Future<void> _initPlatform(AppSettings settings) async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } on Object {
    debugPrint('edge-to-edge unavailable');
  }

  SoundService.init(settings);
  HapticsService.init(settings);
  LauncherIconService.init(settings);
  await ThemeSyncService.init(settings);
}
