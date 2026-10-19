import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:komak/localization/localization.dart';
import 'package:komak/platform/haptics_service.dart';
import 'package:komak/platform/sound_service.dart';
import 'package:komak/settings/app_settings.dart';
import 'package:komak/theme/app_spacing.dart';
import 'package:komak/theme/catppuccin.dart';
import 'package:komak/ui/about_section.dart';
import 'package:komak/ui/language_sheet.dart';
import 'package:komak/ui/widgets/page_frame.dart';
import 'package:komak/ui/widgets/settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                SettingsSection(
                  title: 'Appearance',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SegmentedButton<ThemeMode>(
                        expandedInsets: EdgeInsets.zero,
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Auto'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Latte'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Mocha'),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) =>
                            settings.themeMode = selection.first,
                      ),
                    ),
                    _AccentTile(settings: settings),
                    if (Platform.isAndroid)
                      SwitchListTile(
                        title: const Text('Sync theme'),
                        subtitle: const Text(
                          'Use the same accent and theme in my other apps on this phone',
                        ),
                        value: settings.syncAppearance,
                        onChanged: (value) => settings.syncAppearance = value,
                      ),
                  ],
                ),
                if (L10n.languages.length > 1)
                  SettingsSection(
                    title: 'Language',
                    children: [
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(_languageName(settings.language)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _pickLanguage(context),
                      ),
                    ],
                  ),
                SettingsSection(
                  title: 'Text size',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        spacing: AppSpacing.sm,
                        children: [
                          Text('A', style: Theme.of(context).textTheme.bodySmall),
                          Expanded(
                            child: Slider(
                              value: settings.textScale,
                              min: 0.85,
                              max: 1.35,
                              divisions: 10,
                              label: '${(settings.textScale * 100).round()}%',
                              onChanged: (value) => settings.textScale = value,
                            ),
                          ),
                          Text('A', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Study experience',
                  children: [
                    SwitchListTile(
                      title: const Text('Sound effects'),
                      subtitle: Text(
                        SoundService.isBroken
                            ? 'Sound is not available on this device.'
                            : 'Small taps and chimes while you study.',
                      ),
                      value: settings.soundEnabled && !SoundService.isBroken,
                      onChanged: SoundService.isBroken
                          ? null
                          : (value) => settings.soundEnabled = value,
                    ),
                    if (settings.soundEnabled && !SoundService.isBroken)
                      for (final sound in AppSound.values)
                        SwitchListTile(
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.xl,
                            end: AppSpacing.md,
                          ),
                          dense: true,
                          title: Text(sound.label),
                          subtitle: Text(sound.description),
                          value: !settings.mutedSounds.contains(sound),
                          onChanged: (on) {
                            settings.setSoundMuted(sound, muted: !on);
                            if (on) unawaited(SoundService.play(sound));
                          },
                        ),
                    SwitchListTile(
                      title: const Text('Vibrate on wrong answers'),
                      subtitle: const Text('A short buzz when you miss one.'),
                      value: settings.hapticsEnabled,
                      onChanged: (value) {
                        settings.hapticsEnabled = value;
                        if (value) unawaited(HapticsService.wrong());
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Reduce motion'),
                      subtitle: const Text('Use simpler, shorter animations.'),
                      value: settings.reduceMotion,
                      onChanged: (value) => settings.reduceMotion = value,
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Updates',
                  children: [
                    SwitchListTile(
                      title: const Text('Check for updates'),
                      subtitle: const Text(
                        'Look for a newer version when the app starts',
                      ),
                      value: settings.checkUpdates,
                      onChanged: (value) => settings.checkUpdates = value,
                    ),
                  ],
                ),
                const AboutSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _languageName(String code) {
    if (code == L10n.system) return 'System default'.tr;
    for (final language in L10n.languages) {
      if (language.code == code) return language.name;
    }
    return code;
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final picked = await showLanguageSheet(context, settings.language);
    if (picked != null) settings.language = picked;
  }
}

class _AccentTile extends StatelessWidget {
  const _AccentTile({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark ? CatppuccinPalette.mocha : CatppuccinPalette.latte;
    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: const Text('Accent color'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final name in CatppuccinPalette.accents)
              _AccentDot(
                label: '${name[0].toUpperCase()}${name.substring(1)}'.tr,
                color: palette.accent(name),
                selected: settings.accent == name,
                onTap: () => settings.accent = name,
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const duration = Duration(milliseconds: 200);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: AnimatedScale(
            scale: selected ? 1 : 0,
            duration: duration,
            curve: Curves.easeOutBack,
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: scheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}
