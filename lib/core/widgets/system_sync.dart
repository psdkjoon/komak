import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komak/core/services/app_icon_service.dart';

class SystemSync extends StatefulWidget {
  const SystemSync({super.key, required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  State<SystemSync> createState() => _SystemSyncState();
}

class _SystemSyncState extends State<SystemSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hideStatusBar();
    unawaited(AppIconService.apply(dark: widget.isDark));
  }

  @override
  void didUpdateWidget(SystemSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      unawaited(AppIconService.apply(dark: widget.isDark));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _hideStatusBar();
  }

  @override
  void didChangeMetrics() {
    _hideStatusBar();
  }

  void _hideStatusBar() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: <SystemUiOverlay>[SystemUiOverlay.bottom],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
