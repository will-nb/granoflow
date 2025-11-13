import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/pinned_task_bar.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/pinned_task_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/providers/tasks_drag_provider.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/task_filter_collapsible.dart';
import 'quick_tasks/quick_add_sheet.dart';
import 'utils/date_utils.dart';
import 'views/task_section_panel.dart';

/// Tasks 页面主组件
///
/// 这个页面用来显示所有的任务，按照时间分组展示：
/// - 逾期：已经过了截止日期的任务
/// - 今天：今天要完成的任务
/// - 明天：明天要完成的任务
/// - 本周：这周要完成的任务
/// - 本月：这个月要完成的任务
/// - 以后：以后要完成的任务
///
/// 页面会自动循环生成每个分区，每个分区用 [TaskSectionPanel] 组件来展示任务列表。
/// 如果某个分区没有任务，就不会显示这个分区。
class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({
    super.key,
    this.initialSection,
    this.scrollToPinned = false,
  });

  /// 可选的初始分区参数
  ///
  /// 如果提供了这个参数，页面加载时会自动滚动到指定的分区。
  /// 可以通过路由参数传入，比如从其他地方跳转过来时，直接定位到某个分区。
  ///
  /// 支持的值：
  /// - 'overdue'：逾期分区
  /// - 'today'：今天分区
  /// - 'tomorrow'：明天分区
  /// - 'thisWeek'：本周分区
  /// - 'thisMonth'：本月分区
  /// - 'later'：以后分区
  final String? initialSection;

  /// 是否滚动到置顶任务
  ///
  /// 如果为 true，页面加载时会自动滚动到置顶任务栏的位置。
  final bool scrollToPinned;

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

/// TaskListPage 的内部状态管理类
///
/// 负责管理页面的滚动、自动滚动到指定分区等功能。
class _TaskListPageState extends ConsumerState<TaskListPage> {
  /// 页面滚动的控制器
  ///
  /// 用来控制整个页面的滚动位置，比如滚动到某个分区。
  final ScrollController _scrollController = ScrollController();

  /// 每个分区的全局键（GlobalKey）映射表
  ///
  /// 这些键用来定位每个分区在页面中的位置，方便自动滚动到指定分区。
  /// 比如用户点击某个通知要查看"今天"的任务，就可以用这个键找到"今天"分区并滚动过去。
  final Map<TaskSection, GlobalKey> _sectionKeys = {
    TaskSection.overdue: GlobalKey(),
    TaskSection.today: GlobalKey(),
    TaskSection.tomorrow: GlobalKey(),
    TaskSection.thisWeek: GlobalKey(),
    TaskSection.thisMonth: GlobalKey(),
    TaskSection.nextMonth: GlobalKey(),
    TaskSection.later: GlobalKey(),
  };

  /// 是否已经执行过自动滚动
  ///
  /// 用来确保自动滚动只执行一次，避免重复滚动。
  bool _didAutoScroll = false;

  /// 是否已经滚动到置顶任务
  ///
  /// 用来确保滚动到置顶任务只执行一次。
  bool _didScrollToPinned = false;

  /// 置顶任务栏的全局键
  ///
  /// 用于定位置顶任务栏的位置，方便自动滚动。
  final GlobalKey _pinnedTaskBarKey = GlobalKey();

  /// 是否已经完成初始构建
  ///
  /// 用来区分是首次加载还是数据更新后的重建
  bool _hasCompletedInitialBuild = false;

  /// TasksDragNotifier 的引用，用于在 dispose 中清理
  ///
  /// 不能在 dispose 中使用 ref，所以需要在 initState 中保存引用
  TasksDragNotifier? _dragNotifier;

  @override
  void initState() {
    super.initState();
    // 在下一帧标记初始构建完成，确保只在首次加载时设置
    // 这样在数据更新导致重建时，不会重置滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _hasCompletedInitialBuild = true;
        // 设置 ScrollController 到 TasksDragNotifier，用于边缘自动滚动
        // 同时保存 notifier 引用，以便在 dispose 中使用
        _dragNotifier = ref.read(tasksDragProvider.notifier);
        _dragNotifier?.setScrollController(_scrollController);
        
        // 检查并恢复 doing 状态的任务为置顶
        // 主要用于应用被强制退出后重新进入时，自动恢复 doing 任务的置顶状态
        ref.read(pinnedTaskIdProvider.notifier).checkAndRestoreDoingTask();
        
        // 检查是否需要滚动到置顶任务
        if (widget.scrollToPinned && !_didScrollToPinned) {
          _scrollToPinnedTask();
        }
      }
    });
  }

  @override
  void dispose() {
    // 清除 ScrollController 的引用，避免内存泄漏
    // 注意：不能在 dispose 中使用 ref，所以使用保存的引用
    _dragNotifier?.setScrollController(null);
    // 页面销毁时，释放滚动控制器，避免内存泄漏
    _scrollController.dispose();
    super.dispose();
  }

  /// 构建页面 UI
  ///
  /// 这个方法会：
  /// 1. 定义所有要显示的分区（逾期、今天、明天等）
  /// 2. 循环遍历每个分区，为每个分区生成一个 [TaskSectionPanel] 组件
  /// 3. 如果某个分区没有任务，就不显示这个分区
  /// 4. 如果设置了初始分区，会自动滚动到那个分区
  @override
  Widget build(BuildContext context) {
    // 确保 ScrollController 已设置到 TasksDragNotifier（用于边缘自动滚动）
    final dragNotifier = ref.read(tasksDragProvider.notifier);
    dragNotifier.setScrollController(_scrollController);
    
    final l10n = AppLocalizations.of(context);
    final editActions = ref.watch(taskEditActionsNotifierProvider);
    // 如果正在执行任务操作（比如删除、移动任务），显示顶部的进度条
    final bool showLinearProgress = editActions.isLoading;

    // 定义所有要显示的分区信息
    // 这里定义了页面上会显示的所有分区，按照顺序从上到下排列
    final sectionMetas = <_SectionMeta>[
      _SectionMeta(
        section: TaskSection.overdue,
        title: l10n.plannerSectionOverdueTitle,
      ),
      _SectionMeta(
        section: TaskSection.today,
        title: l10n.plannerSectionTodayTitle,
      ),
      _SectionMeta(
        section: TaskSection.tomorrow,
        title: l10n.plannerSectionTomorrowTitle,
      ),
      _SectionMeta(
        section: TaskSection.thisWeek,
        title: l10n.plannerSectionThisWeekTitle,
      ),
      _SectionMeta(
        section: TaskSection.thisMonth,
        title: l10n.plannerSectionThisMonthTitle,
      ),
      _SectionMeta(
        section: TaskSection.nextMonth,
        title: l10n.plannerSectionNextMonthTitle,
      ),
      _SectionMeta(
        section: TaskSection.later,
        title: l10n.plannerSectionLaterTitle,
      ),
    ];

    return GradientPageScaffold(
      appBar: PageAppBar(title: l10n.taskListPageTitle),
      drawer: const MainDrawer(),
      body: GestureDetector(
        onTap: () {
          // 点击页面空白区域时，移除输入框的焦点（收起键盘）
          FocusManager.instance.primaryFocus?.unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: CustomScrollView(
          controller: _scrollController,
          // 添加这个参数，确保在数据更新时保持滚动位置
          key: const PageStorageKey<String>('tasks_page_scroll'),
          slivers: [
            // 筛选UI
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TaskFilterCollapsible(
                  filterProvider: tasksFilterProvider,
                ),
              ),
            ),
            // 置顶任务栏
            SliverToBoxAdapter(
              key: _pinnedTaskBarKey,
              child: const PinnedTaskBar(),
            ),
            // 如果正在执行任务操作，在顶部显示进度条
            if (showLinearProgress)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  // 循环遍历所有分区，为每个分区生成对应的 UI
                  sectionMetas
                      .expand((meta) => [
                            // 使用 Consumer 来监听每个分区的任务数据变化
                            // 当任务数据更新时，会自动刷新对应的分区显示
                            Consumer(
                              builder: (context, ref, child) {
                                // 从数据源获取这个分区的任务列表
                                final tasksAsync = ref.watch(
                                  taskSectionsProvider(meta.section),
                                );
                                // 根据数据状态（加载中、成功、失败）显示不同的内容
                                return tasksAsync.when(
                                  data: (tasks) {
                                    // 如果这个分区没有任务，就不显示这个分区
                                    if (tasks.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    // 创建分区面板组件，用来显示这个分区的任务列表
                                    final panel = TaskSectionPanel(
                                      key: _sectionKeys[meta.section],
                                      section: meta.section,
                                      title: meta.title,
                                      editMode: false,
                                      onQuickAdd: () =>
                                          _handleQuickAdd(context, meta.section),
                                      tasks: tasks,
                                    );
                                    // 只在首次构建时检查是否需要自动滚动
                                    // 数据更新后的重建不应该触发自动滚动
                                    if (!_hasCompletedInitialBuild) {
                                      _maybeAutoScroll(meta.section);
                                    }
                                    // 检查是否需要滚动到置顶任务
                                    if (widget.scrollToPinned && !_didScrollToPinned) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _scrollToPinnedTask();
                                      });
                                    }
                                    return panel;
                                  },
                                  // 加载中时，不显示任何内容（避免闪烁）
                                  loading: () => const SizedBox.shrink(),
                                  // 加载失败时，也不显示错误（避免影响用户体验）
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                            ),
                          ])
                      .toList(growable: false),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  /// 可能需要自动滚动到指定的分区
  ///
  /// 如果用户在打开页面时指定了要查看的分区（比如通过 initialSection 参数），
  /// 这个方法会在那个分区第一次显示到页面上时，自动滚动到那个分区。
  ///
  /// [builtSection] 当前正在构建的分区
  void _maybeAutoScroll(TaskSection builtSection) {
    // 如果已经滚动过了，就不再滚动
    if (_didAutoScroll) return;
    // 如果已经完成了初始构建，说明这是数据更新后的重建，不应该触发自动滚动
    if (_hasCompletedInitialBuild) return;
    // 解析用户指定的初始分区
    final target = _parseSection(widget.initialSection);
    // 如果用户没有指定，就不滚动
    if (target == null) return;
    // 如果当前构建的分区不是目标分区，就不滚动（等目标分区构建时再滚动）
    if (builtSection != target) return;
    // 在当前这一帧渲染完成后，执行滚动
    // 这样可以确保分区已经完全渲染到页面上，才能正确滚动
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 再次检查，确保在回调执行时仍然需要滚动
      // 只有在初始构建阶段且尚未滚动过时才执行自动滚动
      // 如果已经完成了初始构建（数据更新后的重建），则不执行滚动
      if (_didAutoScroll || _hasCompletedInitialBuild) return;
      final key = _sectionKeys[target];
      final ctx = key?.currentContext;
      if (ctx != null && mounted) {
        _didAutoScroll = true;
        // 平滑滚动到目标分区，滚动时间 350 毫秒
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.05, // 分区显示在页面顶部往下一点的位置（5%）
          curve: Curves.easeInOut, // 使用平滑的滚动动画
        );
      }
    });
  }

  /// 滚动到置顶任务栏
  ///
  /// 当用户点击通知时，自动滚动到置顶任务栏的位置。
  void _scrollToPinnedTask() {
    if (_didScrollToPinned) return;
    if (!_scrollController.hasClients) return;

    final key = _pinnedTaskBarKey;
    final ctx = key.currentContext;
    if (ctx != null && mounted) {
      _didScrollToPinned = true;
      // 平滑滚动到置顶任务栏，滚动时间 350 毫秒
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.0, // 置顶栏显示在页面顶部
        curve: Curves.easeInOut, // 使用平滑的滚动动画
      );
    }
  }

  /// 把字符串转换成对应的分区枚举值
  ///
  /// 比如 'today' 会转换成 [TaskSection.today]。
  /// 如果字符串不匹配任何一个分区，就返回 null。
  ///
  /// [raw] 原始字符串，比如 'today'、'tomorrow' 等
  /// 返回对应的分区枚举值，如果不匹配就返回 null
  TaskSection? _parseSection(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'overdue':
        return TaskSection.overdue;
      case 'today':
        return TaskSection.today;
      case 'tomorrow':
        return TaskSection.tomorrow;
      case 'thisWeek':
        return TaskSection.thisWeek;
      case 'thisMonth':
        return TaskSection.thisMonth;
      case 'nextMonth':
        return TaskSection.nextMonth;
      case 'later':
        return TaskSection.later;
      default:
        return null;
    }
  }

  /// 处理快速添加任务的操作
  ///
  /// 当用户点击某个分区标题旁边的"快速添加"按钮时，会调用这个方法。
  /// 这个方法会：
  /// 1. 弹出一个底部弹窗，让用户输入任务标题和选择截止日期
  /// 2. 创建一个新任务并保存到数据库中
  /// 3. 把任务规划到指定的分区（设置对应的截止日期）
  /// 4. 显示成功或失败的提示消息
  ///
  /// [context] 页面上下文，用来显示弹窗和提示消息
  /// [section] 要添加任务的分区（比如"今天"、"明天"等）
  Future<void> _handleQuickAdd(
    BuildContext context,
    TaskSection section,
  ) async {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final maxHeight = isLandscape 
        ? mediaQuery.size.height * 0.5
        : double.infinity;

    // 弹出底部弹窗，让用户输入任务信息（与导航栏样式保持一致）
    final result = await showModalBottomSheet<QuickAddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // QuickAddSheet
              QuickAddSheet(section: section),
              // 底部安全区域
              SizedBox(height: mediaQuery.viewPadding.bottom + 20),
            ],
          ),
        ),
      ),
    );
    // 如果用户取消输入（点击取消或点击空白处），就不做任何操作
    if (result == null) {
      return;
    }

    final taskService = await ref.read(taskServiceProvider.future);
    try {
      // 先创建一个新任务，保存到收件箱
      final newTask = await taskService.captureInboxTask(title: result.title);
      // 然后把任务规划到指定的分区（设置截止日期）
      // 因为有 section，所以 dueDate 应该总是有值
      final dueDate = result.dueDate ?? defaultDueDate(section);
      await taskService.planTask(
        taskId: newTask.id,
        dueDateLocal: dueDate,
        section: section,
      );
      // 检查页面是否还存在（用户可能已经关闭了页面）
      if (!context.mounted) {
        return;
      }
      // 显示成功提示消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taskListAddedToast)));
    } catch (error, stackTrace) {
      // 如果出错了，打印错误信息到控制台（方便调试）
      debugPrint('Failed to add task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      // 显示失败提示消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taskListAddError)));
    }
  }
}

/// 分区元数据类
///
/// 用来保存每个分区的信息，包括分区类型和显示的标题。
/// 这个类很简单，就是把分区枚举值和标题打包在一起，方便在循环中使用。
class _SectionMeta {
  const _SectionMeta({required this.section, required this.title});

  /// 分区类型，比如 TaskSection.today（今天）、TaskSection.tomorrow（明天）等
  final TaskSection section;

  /// 分区显示的标题文字，比如"今天"、"明天"等（会根据用户的语言设置显示不同文字）
  final String title;
}
