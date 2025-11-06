import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/constants/font_scale_constants.dart';
import '../../core/constants/font_scale_level.dart';
import '../../core/providers/pomodoro_audio_preference_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../completion_management/completed_page.dart';
import '../completion_management/trash_page.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';

class SettingsControlsPage extends ConsumerWidget {
  const SettingsControlsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const Locale('en'),
        );
    final fontScaleLevel = ref.watch(fontScaleLevelProvider).maybeWhen(
          data: (value) => value,
          orElse: () => FontScaleConstants.getDefaultLevel(),
        );
    final themeMode = ref.watch(themeProvider).maybeWhen(
          data: (value) => value,
          orElse: () => ThemeMode.system,
        );

    final prefActions = ref.watch(preferenceActionsNotifierProvider);
    final actionsNotifier =
        ref.read(preferenceActionsNotifierProvider.notifier);
    final isLoading = prefActions.isLoading;

    final localeOptions = <String, String>{
      'en': l10n.settingsLanguageEnglish,
      'zh_CN': l10n.settingsLanguageSimplifiedChinese,
      'zh_HK': l10n.settingsLanguageTraditionalChinese,
    };

    // 字体大小级别标签映射（不受屏幕方向影响）
    final fontLabels = <FontScaleLevel, String>{
      FontScaleLevel.small: l10n.settingsFontSizeSmall,
      FontScaleLevel.medium: l10n.settingsFontSizeMedium,
      FontScaleLevel.large: l10n.settingsFontSizeLarge,
      FontScaleLevel.xlarge: l10n.settingsFontSizeXLarge,
    };

    final themeOptions = <ThemeMode, String>{
      ThemeMode.system: l10n.settingsThemeSystem,
      ThemeMode.light: l10n.settingsThemeLight,
      ThemeMode.dark: l10n.settingsThemeDark,
    };

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.settings,
      ),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
        _SettingCard(
          title: l10n.settingsLanguageLabel,
          child: DropdownMenu<String>(
            initialSelection: locale.languageCode + (locale.countryCode != null ? '_${locale.countryCode}' : ''),
            enabled: !isLoading,
            onSelected: (value) async {
              final currentLocale = locale.languageCode + (locale.countryCode != null ? '_${locale.countryCode}' : '');
              print('Language selection: $value, current: $currentLocale');
              if (value != null && value != currentLocale) {
                print('Updating locale to: $value');
                await actionsNotifier.updateLocale(value);
              } else {
                print('No locale change needed');
              }
            },
            dropdownMenuEntries: localeOptions.entries
                .map(
                  (entry) => DropdownMenuEntry<String>(
                    value: entry.key,
                    label: entry.value,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SettingCard(
          title: l10n.settingsFontSizeLabel,
          child: SegmentedButton<FontScaleLevel>(
            segments: FontScaleLevel.values
                .map(
                  (level) => ButtonSegment<FontScaleLevel>(
                    value: level,
                    label: Text(fontLabels[level] ?? level.name),
                  ),
                )
                .toList(),
            selected: <FontScaleLevel>{
              fontScaleLevel,
            },
            onSelectionChanged: isLoading
                ? null
                : (selection) async {
                    final selected = selection.first;
                    if (selected != fontScaleLevel) {
                      await actionsNotifier.updateFontScaleLevel(selected);
                    }
                  },
          ),
        ),
        const SizedBox(height: 16),
        _SettingCard(
          title: l10n.settingsThemeLabel,
          child: SegmentedButton<ThemeMode>(
            segments: themeOptions.entries
                .map(
                  (entry) => ButtonSegment<ThemeMode>(
                    value: entry.key,
                    label: Text(entry.value),
                  ),
                )
                .toList(),
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: isLoading
                ? null
                : (selection) async {
                    final selected = selection.first;
                    if (selected != themeMode) {
                      await actionsNotifier.updateTheme(selected);
                    }
                  },
          ),
        ),
        const SizedBox(height: 16),
        _SettingCard(
          title: l10n.settingsPomodoroSection,
          child: const _PomodoroTickSoundSwitch(),
        ),
        const SizedBox(height: 16),
        _SettingCard(
          title: l10n.settingsTaskManagement,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text(l10n.appShellCompleted),
                subtitle: Text(l10n.settingsViewCompletedTasks),
                onTap: () {
                  // Navigate to completed tasks
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompletedPage(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.appShellTrash),
                subtitle: Text(l10n.settingsViewDeletedTasks),
                onTap: () {
                  // Navigate to trash
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TrashPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// 番茄时钟音频开关组件
class _PomodoroTickSoundSwitch extends ConsumerWidget {
  const _PomodoroTickSoundSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final audioEnabledAsync = ref.watch(pomodoroTickSoundEnabledProvider);
    
    return audioEnabledAsync.when(
      data: (enabled) => SwitchListTile(
        title: Text(l10n.settingsPomodoroTickSound),
        subtitle: Text(l10n.settingsPomodoroTickSoundDescription),
        value: enabled,
        onChanged: (value) {
          updatePomodoroTickSoundEnabled(ref, value);
        },
      ),
      loading: () => ListTile(
        title: Text(l10n.commonLoading),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => ListTile(
        title: Text(l10n.commonLoadFailed),
      ),
    );
  }
}