import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/task_template.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/error_banner.dart';
import '../widgets/inbox_tag_filter_strip.dart';
import '../widgets/inbox_filter_collapsible.dart';

class InboxCaptureSection extends ConsumerWidget {
  const InboxCaptureSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmit,
    required this.onTemplateApply,
    required this.currentQuery,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final ValueChanged<String> onChanged;
  final Future<void> Function(String value) onSubmit;
  final Future<void> Function(TaskTemplate template) onTemplateApply;
  final String currentQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final templateSuggestions = ref.watch(
      templateSuggestionsProvider(
        TemplateSuggestionQuery(
          text: currentQuery.isEmpty ? null : currentQuery,
          limit: 6,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InboxInputField(
            controller: controller,
            focusNode: focusNode,
            isSubmitting: isSubmitting,
            placeholder: l10n.inboxQuickAddPlaceholder,
            onChanged: onChanged,
            onSubmit: onSubmit,
          ),
          const SizedBox(height: 12),
          templateSuggestions.when(
            data: (templates) => InboxTemplateSuggestionWrap(
              templates: templates,
              onApply: onTemplateApply,
              emptyLabel: l10n.inboxTemplateEmpty,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => ErrorBanner(message: '$error'),
          ),
          const SizedBox(height: 16),
          const InboxFilterCollapsible(),
        ],
      ),
    );
  }
}

class _InboxInputField extends StatelessWidget {
  const _InboxInputField({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.placeholder,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final Future<void> Function(String value) onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: (value) {
        onSubmit(value);
      },
      decoration: InputDecoration(
        hintText: placeholder,
        suffixIcon: isSubmitting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.send),
                tooltip: l10n.commonAdd,
                onPressed: () => onSubmit(controller.text),
              ),
      ),
    );
  }
}

class InboxTemplateSuggestionWrap extends StatelessWidget {
  const InboxTemplateSuggestionWrap({
    super.key,
    required this.templates,
    required this.onApply,
    required this.emptyLabel,
  });

  final List<TaskTemplate> templates;
  final Future<void> Function(TaskTemplate template) onApply;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          emptyLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates
          .map(
            (template) => ActionChip(
              label: Text(template.title),
              avatar: const Icon(Icons.auto_awesome_outlined),
              onPressed: () => onApply(template),
            ),
          )
          .toList(growable: false),
    );
  }
}

