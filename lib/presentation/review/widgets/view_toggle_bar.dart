import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/theme/ocean_breeze_color_schemes.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 视图切换工具栏
/// 支持日/周/月视图切换
class ViewToggleBar extends ConsumerWidget {
  const ViewToggleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    final notifier = ref.read(calendarReviewNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ToggleButton(
            label: l10n.calendarReviewDayView,
            isSelected: state.viewMode == CalendarViewMode.day,
            onTap: () => notifier.setViewMode(CalendarViewMode.day),
          ),
          const SizedBox(width: 8),
          _ToggleButton(
            label: l10n.calendarReviewWeekView,
            isSelected: state.viewMode == CalendarViewMode.week,
            onTap: () => notifier.setViewMode(CalendarViewMode.week),
          ),
          const SizedBox(width: 8),
          _ToggleButton(
            label: l10n.calendarReviewMonthView,
            isSelected: state.viewMode == CalendarViewMode.month,
            onTap: () => notifier.setViewMode(CalendarViewMode.month),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? OceanBreezeColorSchemes.lakeCyan
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
