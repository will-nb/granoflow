import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/theme/app_spacing_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import '../navigation/navigation_destinations.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/task_filter_collapsible.dart';
import 'views/inbox_task_list.dart';
import 'widgets/inbox_empty_state_card.dart';
import 'widgets/inbox_quick_add_sheet.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
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
            // 筛选UI
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TaskFilterCollapsible(
                  filterProvider: inboxFilterProvider,
                ),
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

                final spacingTokens = Theme.of(context).extension<AppSpacingTokens>() ?? AppSpacingTokens.light;

                return SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacingTokens.cardHorizontalPadding,
                        vertical: spacingTokens.cardVerticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.inbox,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _handleQuickAdd(context),
                                icon: const Icon(Icons.add_task_outlined),
                                tooltip: l10n.taskListQuickAddTooltip,
                              ),
                            ],
                          ),
                          SizedBox(height: spacingTokens.sectionInternalSpacing),
                          InboxTaskList(tasks: tasks),
                        ],
                      ),
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

  /// 处理快速添加任务
  ///
  /// 弹出底部弹窗让用户输入任务标题，然后创建 status=inbox, dueDate=null 的任务
  Future<void> _handleQuickAdd(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    // 弹出底部弹窗，让用户输入任务标题
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const InboxQuickAddSheet(),
    );
    // 如果用户取消输入（点击取消或点击空白处），就不做任何操作
    if (title == null || title.isEmpty) {
      return;
    }

    final taskService = ref.read(taskServiceProvider);
    try {
      // 创建 inbox 任务，status=inbox, dueDate=null
      await taskService.captureInboxTask(title: title);
      // 检查页面是否还存在（用户可能已经关闭了页面）
      if (!context.mounted) {
        return;
      }
      // 显示成功提示消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.inboxAddedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to add inbox task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      // 显示失败提示消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.inboxAddError}: $error')));
    }
  }
}
