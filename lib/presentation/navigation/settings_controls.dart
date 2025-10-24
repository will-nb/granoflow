import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import '../completion_management/completed_page.dart';
import '../completion_management/trash_page.dart';

class SettingsControlsPage extends ConsumerWidget {
  const SettingsControlsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const Locale('en'),
        );
    final fontScale = ref.watch(fontScaleProvider).maybeWhen(
          data: (value) => value,
          orElse: () => 1.0,
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
      'zh_Hans': l10n.settingsLanguageSimplifiedChinese,
      'zh_Hant': l10n.settingsLanguageTraditionalChinese,
    };

    const fontOptions = <double>[0.875, 1.0, 1.125, 1.25];

    final themeOptions = <ThemeMode, String>{
      ThemeMode.system: l10n.settingsThemeSystem,
      ThemeMode.light: l10n.settingsThemeLight,
      ThemeMode.dark: l10n.settingsThemeDark,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettingsSectionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingCard(
            title: l10n.settingsLanguageLabel,
            child: DropdownMenu<String>(
              initialSelection: locale.languageCode,
              enabled: !isLoading,
              onSelected: (value) async {
                if (value != null && value != locale.languageCode) {
                  await actionsNotifier.updateLocale(value);
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
            child: SegmentedButton<double>(
              segments: fontOptions
                  .map(
                    (value) => ButtonSegment<double>(
                      value: value,
                      label: Text(value.toStringAsFixed(2)),
                    ),
                  )
                  .toList(),
              selected: <double>{fontScale},
              onSelectionChanged: isLoading
                  ? null
                  : (selection) async {
                      final selected = selection.first;
                      if (selected != fontScale) {
                        await actionsNotifier.updateFontScale(selected);
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
            title: '任务管理', // TODO: Add to localizations
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(l10n.appShellCompleted),
                  subtitle: const Text('查看已完成的任务'),
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
                  subtitle: const Text('查看已删除的任务'),
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
