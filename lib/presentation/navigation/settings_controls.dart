import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/constants/font_scale_constants.dart';
import '../../core/constants/font_scale_level.dart';
import '../../core/providers/clock_audio_preference_provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/modern_tag_group.dart';
import '../widgets/modern_tag.dart';
import '../widgets/tag_data.dart';
import '../../data/models/tag.dart';
import 'widgets/export_import_section.dart';

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

    // 为每种语言创建 TagData
    final languageTags = localeOptions.entries.map((entry) {
      final localeCode = entry.key;
      final label = entry.value;
      // 为不同语言分配不同的颜色
      final color = _getLanguageColor(localeCode, context);
      return TagData(
        slug: localeCode,
        label: label,
        color: color,
        kind: TagKind.special, // 语言标签使用 special 类型
      );
    }).toList();

    // 当前选中的语言
    final currentLocaleCode = locale.languageCode + 
        (locale.countryCode != null ? '_${locale.countryCode}' : '');
    final selectedLanguageTags = <String>{
      if (localeOptions.containsKey(currentLocaleCode)) currentLocaleCode
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
          child: Opacity(
            opacity: isLoading ? 0.5 : 1.0,
            child: ModernTagGroup(
              tags: languageTags,
              selectedTags: selectedLanguageTags,
              multiSelect: false,
              variant: TagVariant.pill,
              size: TagSize.medium,
              spacing: 8.0,
              runSpacing: 8.0,
              onSelectionChanged: isLoading
                  ? (_) {}
                  : (selected) {
                      if (selected.isNotEmpty) {
                        final selectedLocale = selected.first;
                        if (selectedLocale != currentLocaleCode) {
                          actionsNotifier.updateLocale(selectedLocale);
                        }
                      }
                    },
            ),
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
          title: l10n.settingsClockSection,
          child: const _ClockTickSoundSwitch(),
        ),
        const SizedBox(height: 16),
        _SettingCard(
          title: l10n.settingsExportImportSection,
          child: const ExportImportSection(),
        ),
      ],
    ),
    );
  }
}
/// 获取语言对应的颜色
Color _getLanguageColor(String localeCode, BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  // 为不同语言分配不同的颜色
  switch (localeCode) {
    case 'en':
      return colorScheme.primary;
    case 'zh_CN':
      return Colors.red.shade600;
    case 'zh_HK':
      return Colors.orange.shade600;
    default:
      return colorScheme.secondary;
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

/// 计时器音频开关组件
class _ClockTickSoundSwitch extends ConsumerWidget {
  const _ClockTickSoundSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final audioEnabledAsync = ref.watch(clockTickSoundEnabledProvider);
    
    return audioEnabledAsync.when(
      data: (enabled) => SwitchListTile(
        title: Text(l10n.settingsClockTickSound),
        subtitle: Text(l10n.settingsClockTickSoundDescription),
        value: enabled,
        onChanged: (value) {
          updateClockTickSoundEnabled(ref, value);
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