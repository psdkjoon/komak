import 'package:flutter/material.dart';
import 'package:komak/core/services/sound_service.dart';
import 'package:komak/core/models/app_settings.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/theme/app_theme.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/sliver_content.dart';
import 'package:komak/core/widgets/theme_toggle_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final AppSettings settings = controller.settings;
        final ThemeData theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverContent(
                  maxWidth: AppLayout.readableMaxWidth,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        SectionCard(
                          title: 'Appearance',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'The sun/moon button on the home screen switches themes any time.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const ThemeToggleButton(size: 40),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Match system theme'),
                                subtitle: const Text(
                                    "Follow your device's light/dark setting.",),
                                value: settings.followSystemTheme,
                                onChanged: (bool value) {
                                  controller.updateSettings((AppSettings s) =>
                                      s.copyWith(followSystemTheme: value),);
                                },
                              ),
                              if (!settings.followSystemTheme) ...<Widget>[
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _ThemeOption(
                                        label: 'Latte',
                                        isDark: false,
                                        selected: settings.themeVariant ==
                                            AppThemeVariant.latte,
                                        onTap: () => controller.updateSettings(
                                          (AppSettings s) => s.copyWith(
                                              themeVariant:
                                                  AppThemeVariant.latte,),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _ThemeOption(
                                        label: 'Mocha',
                                        isDark: true,
                                        selected: settings.themeVariant ==
                                            AppThemeVariant.mocha,
                                        onTap: () => controller.updateSettings(
                                          (AppSettings s) => s.copyWith(
                                              themeVariant:
                                                  AppThemeVariant.mocha,),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SectionCard(
                          title: 'Text size',
                          child: Row(
                            children: <Widget>[
                              const Text('A', style: TextStyle(fontSize: 13)),
                              Expanded(
                                child: Slider(
                                  value: settings.textScale,
                                  min: 0.85,
                                  max: 1.35,
                                  divisions: 10,
                                  label:
                                      '${(settings.textScale * 100).round()}%',
                                  onChanged: (double value) {
                                    controller.updateSettings((AppSettings s) =>
                                        s.copyWith(textScale: value),);
                                  },
                                ),
                              ),
                              const Text('A', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SectionCard(
                          title: 'Study experience',
                          child: Column(
                            children: <Widget>[
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Sound effects'),
                                subtitle: Text(
                                  controller.sound.isBroken
                                      ? 'Sound is not available on this device.'
                                      : 'Small taps and chimes while you study.',
                                ),
                                value: settings.soundEnabled &&
                                    !controller.sound.isBroken,
                                onChanged: controller.sound.isBroken
                                    ? null
                                    : (bool value) {
                                        controller.updateSettings(
                                            (AppSettings s) => s.copyWith(
                                                soundEnabled: value,),);
                                      },
                              ),
                              if (settings.soundEnabled &&
                                  !controller.sound.isBroken)
                                for (final AppSound sound in AppSound.values)
                                  SwitchListTile(
                                    contentPadding: const EdgeInsets.only(
                                        left: AppSpacing.lg,),
                                    dense: true,
                                    title: Text(sound.label),
                                    subtitle: Text(sound.description),
                                    value:
                                        !settings.mutedSounds.contains(sound),
                                    onChanged: (bool on) {
                                      final Set<AppSound> next =
                                          Set<AppSound>.of(
                                              settings.mutedSounds,);
                                      on ? next.remove(sound) : next.add(sound);
                                      controller.updateSettings(
                                          (AppSettings s) =>
                                              s.copyWith(mutedSounds: next),);
                                      if (on) controller.sound.play(sound);
                                    },
                                  ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Vibrate on wrong answers'),
                                subtitle: const Text(
                                    'A short buzz when you miss one.',),
                                value: settings.hapticsEnabled,
                                onChanged: (bool value) {
                                  controller.updateSettings((AppSettings s) =>
                                      s.copyWith(hapticsEnabled: value),);
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Reduce motion'),
                                subtitle: const Text(
                                    'Use simpler, shorter animations.',),
                                value: settings.reduceMotion,
                                onChanged: (bool value) {
                                  controller.updateSettings((AppSettings s) =>
                                      s.copyWith(reduceMotion: value),);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'komak',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption(
      {required this.label,
      required this.isDark,
      required this.selected,
      required this.onTap,});

  final String label;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background =
        isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5);
    final Color foreground =
        isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Durations.short3,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2.4,),
        ),
        child: Center(
            child: Text(label,
                style:
                    TextStyle(color: foreground, fontWeight: FontWeight.w600),),),
      ),
    );
  }
}
