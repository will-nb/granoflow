import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task_template.dart';
import '../../generated/l10n/app_localizations.dart';
import '../navigation/navigation_destinations.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import 'sections/inbox_capture_section.dart';
import 'views/inbox_task_list.dart';
import 'widgets/inbox_empty_state_card.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isSubmitting = false;
  String _currentQuery = '';

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(inboxTasksProvider);

    return GradientPageScaffold(
      appBar: const PageAppBar(title: 'Inbox'),
      drawer: const MainDrawer(),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: InboxCaptureSection(
                controller: _inputController,
                focusNode: _inputFocusNode,
                isSubmitting: _isSubmitting,
                currentQuery: _currentQuery,
                onChanged: (value) => setState(() => _currentQuery = value),
                onSubmit: (value) => _handleSubmit(context, value),
                onTemplateApply: (template) => _applyTemplate(context, template),
              ),
            ),
            tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: InboxEmptyStateCard(
                        title: l10n.inboxEmptyTitle,
                        message: l10n.inboxEmptyMessage,
                        actionLabel: l10n.inboxEmptyAction,
                        onAction: () {
                          final navigator = Navigator.of(context);
                          navigator.popUntil((route) => route.isFirst);
                          ref.read(navigationIndexProvider.notifier).state =
                              NavigationDestinations.tasks.index;
                        },
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: InboxTaskList(tasks: tasks),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stackTrace) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorBanner(message: '$error'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, String value) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final title = value.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxInputEmpty)));
      return;
    }
    setState(() => _isSubmitting = true);
    final taskService = ref.read(taskServiceProvider);
    try {
      await taskService.captureInboxTask(title: title);
      if (!context.mounted) {
        return;
      }
      _inputController.clear();
      _focusNodeRequest();
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxAddedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to add inbox task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxAddError}: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _applyTemplate(BuildContext context, TaskTemplate template) async {
    final templateService = ref.read(taskTemplateServiceProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await templateService.applyTemplate(templateId: template.id);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxTemplateApplied)));
    } catch (error, stackTrace) {
      debugPrint('Failed to apply template in inbox: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxTemplateError}: $error')));
    }
  }

  void _focusNodeRequest() {
    Future.microtask(() {
      if (_inputFocusNode.canRequestFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }
}
