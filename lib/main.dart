import 'package:flutter/material.dart';
import 'package:komak/app.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/services/storage_service.dart';
import 'package:komak/core/widgets/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StorageService storageService = await StorageService.create();
  final SoundService soundService = SoundService();
  final AppController controller = AppController(storageService, soundService);
  await controller.initialize();

  runApp(
    AppScope(
      controller: controller,
      child: const PsdkKomakApp(),
    ),
  );
}
