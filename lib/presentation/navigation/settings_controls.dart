import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
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
      'zh_CN': l10n.settingsLanguageSimplifiedChinese,
      'zh_HK': l10n.settingsLanguageTraditionalChinese,
    };

    // 根据屏幕方向选择字体选项
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    
    // 竖屏：更小的字体以适应更多内容
    // 横屏：相对较大的字体
    final fontOptions = isPortrait 
        ? <double>[0.75, 0.85, 1.0, 1.125]
        : <double>[0.85, 1.0, 1.125, 1.25];
    
    // 字体大小标签映射
    final fontLabels = isPortrait
        ? <double, String>{
            0.75: l10n.settingsFontSizeSmall,
            0.85: l10n.settingsFontSizeMedium,
            1.0: l10n.settingsFontSizeLarge,
            1.125: l10n.settingsFontSizeXLarge,
          }
        : <double, String>{
            0.85: l10n.settingsFontSizeSmall,
            1.0: l10n.settingsFontSizeMedium,
            1.125: l10n.settingsFontSizeLarge,
            1.25: l10n.settingsFontSizeXLarge,
          };

    final themeOptions = <ThemeMode, String>{
      ThemeMode.system: l10n.settingsThemeSystem,
      ThemeMode.light: l10n.settingsThemeLight,
      ThemeMode.dark: l10n.settingsThemeDark,
    };

    return GradientPageScaffold(
      appBar: const PageAppBar(
        title: 'Settings',
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
          child: SegmentedButton<double>(
            segments: fontOptions
                .map(
                  (value) => ButtonSegment<double>(
                    value: value,
                    label: Text(fontLabels[value] ?? value.toString()),
                  ),
                )
                .toList(),
            selected: <double>{
              // 如果当前字体不在选项中，选择最接近的
              fontOptions.contains(fontScale)
                  ? fontScale
                  : fontOptions.reduce((a, b) =>
                      (a - fontScale).abs() < (b - fontScale).abs() ? a : b)
            },
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