import 'package:flutter/material.dart';
import '../../../widgets/flexible_description_input.dart';
import '../../../widgets/flexible_text_input.dart';
import '../../utils/date_utils.dart';
import '../models/milestone_draft.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// 里程碑草稿项组件
/// 用于在项目创建表单中显示和编辑单个里程碑草稿
class MilestoneDraftTile extends StatelessWidget {
  const MilestoneDraftTile({
    super.key,
    required this.draft,
    required this.onRemove,
    required this.onPickDeadline,
    required this.onChanged,
  });

  final MilestoneDraft draft;
  final VoidCallback onRemove;
  final Future<void> Function() onPickDeadline;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FlexibleTextInput(
                    controller: draft.titleController,
                    softLimit: 50,
                    hardLimit: 255,
                    hintText: l10n.projectSheetMilestoneTitleHint,
                    labelText: l10n.taskListInputLabel,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.deadline != null
                        ? formatDeadline(context, draft.deadline) ?? ''
                        : l10n.projectSheetSelectDeadlineHint,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickDeadline,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l10n.projectSheetSelectDeadline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FlexibleDescriptionInput(
              controller: draft.descriptionController,
              softLimit: 200,
              hardLimit: 60000,
              hintText: l10n.projectSheetDescriptionHint,
              labelText: l10n.flexibleDescriptionLabel,
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

