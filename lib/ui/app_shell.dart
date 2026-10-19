import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:komak/app_info.dart';
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/notification_service.dart';
import 'package:komak/settings/app_settings.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/ui/home_screen.dart';
import 'package:komak/ui/progress_screen.dart';
import 'package:komak/ui/settings_screen.dart';
import 'package:komak/ui/update_prompt.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppShell extends StatefulWidget {
  const AppShell({required this.settings, super.key});

  final AppSettings settings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _sidebarBreakpoint = 800;
  static const _destinations = [
    _Destination('Home', Icons.home_outlined, Icons.home_rounded),
    _Destination('Progress', Icons.insights_outlined, Icons.insights_rounded),
    _Destination('Settings', Icons.tune_rounded, Icons.tune_rounded),
  ];

  static var _lastIndex = 0;

  var _index = _lastIndex;

  @override
  void initState() {
    super.initState();
    if (AppInfo.usesNotifications) NotificationService.requestPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdatePrompt.run(context, widget.settings);
    });
  }

  void _select(int index) => setState(() => _index = _lastIndex = index);

  @override
  Widget build(BuildContext context) {
    final page = SafeArea(
      child: switch (_index) {
        0 => const HomeScreen(),
        1 => const ProgressScreen(),
        _ => SettingsScreen(settings: widget.settings),
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: theme.colorScheme.surfaceContainerLow,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    final Widget scaffold;
    if (MediaQuery.sizeOf(context).width >= _sidebarBreakpoint) {
      scaffold = Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              destinations: _destinations,
              selectedIndex: _index,
              onSelected: _select,
            ),
            Expanded(child: page),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label.tr,
              ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: scaffold,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _width = 11 * AppSpacing.spaceUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: _width,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      AppInfo.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                for (var i = 0; i < destinations.length; i++)
                  ListTile(
                    selected: i == selectedIndex,
                    leading: Icon(
                      i == selectedIndex
                          ? destinations[i].selectedIcon
                          : destinations[i].icon,
                    ),
                    title: Text(destinations[i].label),
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
