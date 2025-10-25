// ============================================================================
// 📋 YAML 架构文档验证测试 - Pages
// ============================================================================
//
// ⚠️ 重要说明：本测试文件用于验证代码实现与 YAML 架构文档的一致性
//
// 🎯 测试目的：
// 1. 确保 documents/architecture/pages/*.yaml 文档准确反映代码实现
// 2. 防止代码变更导致文档与实际不符
// 3. 作为架构文档的"回归测试"，锁定设计规范
//
// ⛔ 禁止行为：
// 1. **绝对不要为了通过测试而修改 YAML 文件**
// 2. **绝对不要删除或跳过失败的测试**
// 3. **绝对不要在未经用户确认的情况下修改 YAML 内容**
//
// ✅ 正确处理流程（当测试失败时）：
// 1. 完成所有测试，收集所有失败信息
// 2. 立即中断操作，不要尝试修复
// 3. 列出所有与 YAML 冲突的修改点
// 4. 询问用户：
//    - 选项 A：修改 YAML 文档以匹配新的代码实现
//    - 选项 B：修改代码以匹配 YAML 文档规范
//    - 选项 C：讨论是否需要调整设计
// 5. 等待用户明确指示后再进行修改
//
// 📝 测试失败意味着：
// - 代码实现偏离了文档规范（可能是有意的改进，也可能是错误）
// - 需要人工判断是更新文档还是修正代码
// - 这是一个设计决策点，不应由 AI 自动处理
//
// ============================================================================

import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:flutter_test/flutter_test.dart';
import 'yaml_test_helper.dart';

class PagesYAMLTest {
  static late Map<String, dynamic> homePageYaml;
  static late Map<String, dynamic> inboxPageYaml;
  static late Map<String, dynamic> taskListPageYaml;
  static late Map<String, dynamic> timerPageYaml;
  static late Map<String, dynamic> completedPageYaml;
  static late Map<String, dynamic> trashPageYaml;
  static late Map<String, dynamic> achievementsPageYaml;

  static Future<void> loadYAMLFiles() async {
    homePageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/home_page.yaml').readAsString()));
    inboxPageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/inbox_page.yaml').readAsString()));
    taskListPageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/task_list_page.yaml').readAsString()));
    timerPageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/timer_page.yaml').readAsString()));
    completedPageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/completed_page.yaml').readAsString()));
    trashPageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/trash_page.yaml').readAsString()));
    achievementsPageYaml = yamlToMap(loadYaml(await File('documents/architecture/pages/achievements_page.yaml').readAsString()));
  }

  // 验证 HomePage
  static void validateHomePage() {
    // 验证 YAML 文件存在
    expect(homePageYaml, isNotNull, reason: 'HomePage YAML file should exist');
    
    // 验证元数据
    expect(homePageYaml['meta']['name'], equals('HomePage'));
    expect(homePageYaml['meta']['type'], equals('page'));
    expect(homePageYaml['meta']['file_path'], equals('lib/presentation/home/home_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(homePageYaml['page_definition']);
    expect(pageDef['name'], equals('HomePage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/'));
    expect(pageDef['title'], equals('Home'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面类型
    final pageTypes = yamlToList(homePageYaml['page_types']);
    expect(pageTypes.length, equals(1), reason: 'HomePage should have 1 page type');
    expect(pageTypes.any((type) => type['name'] == 'ConsumerWidget'), isTrue);
    
    // 验证页面属性
    final properties = yamlToList(homePageYaml['page_properties']);
    expect(properties.length, equals(1), reason: 'HomePage should have 1 property');
    
    final keyProperty = properties.firstWhere((p) => p['name'] == 'key');
    expect(keyProperty['type'], equals('Key?'));
    expect(keyProperty['required'], equals(false));
    
    // 验证页面方法
    final methods = yamlToList(homePageYaml['page_methods']);
    expect(methods.length, equals(1), reason: 'HomePage should have 1 method');
    
    final buildMethod = methods.firstWhere((m) => m['name'] == 'build');
    expect(buildMethod['return_type'], equals('Widget'));
    expect(buildMethod['parameters'].length, equals(2));
    
    // 验证页面状态
    final state = yamlToList(homePageYaml['page_state']);
    expect(state.length, equals(1), reason: 'HomePage should have 1 state');
    
    final seedInitializerState = state.firstWhere((s) => s['name'] == 'seedInitializer');
    expect(seedInitializerState['type'], equals('AsyncValue<void>'));
    expect(seedInitializerState['initial_value'], equals('AsyncValue.loading()'));
    
    // 验证页面事件
    final events = yamlToList(homePageYaml['page_events']);
    expect(events.length, equals(1), reason: 'HomePage should have 1 event');
    
    final onNavigationEvent = events.firstWhere((e) => e['name'] == 'onNavigation');
    expect(onNavigationEvent['description'], equals('导航事件'));
    expect(onNavigationEvent['trigger'], equals('用户点击导航按钮'));
    expect(onNavigationEvent['handler'], equals('导航处理函数'));
    expect(onNavigationEvent['parameters'], equals('导航目标'));
    
    // 验证页面样式
    final styling = yamlToList(homePageYaml['page_styling']);
    expect(styling.length, equals(2), reason: 'HomePage should have 2 styling');
    
    final pageStyle = styling.firstWhere((s) => s['name'] == 'pageStyle');
    expect(pageStyle['description'], equals('页面样式'));
    expect(pageStyle['responsive'], equals(true));
    expect(pageStyle['theme_aware'], equals(true));
    
    final textStyle = styling.firstWhere((s) => s['name'] == 'textStyle');
    expect(textStyle['description'], equals('文字样式'));
    expect(textStyle['responsive'], equals(true));
    expect(textStyle['theme_aware'], equals(true));
    
    // 验证页面响应式
    final responsive = yamlToList(homePageYaml['page_responsive']);
    expect(responsive.length, equals(3), reason: 'HomePage should have 3 responsive breakpoints');
    
    final mobileResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'mobile');
    expect(mobileResponsive['description'], equals('移动端响应式'));
    expect(mobileResponsive['layout'], equals('Column 布局'));
    expect(mobileResponsive['behavior'], equals('垂直排列'));
    
    final tabletResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'tablet');
    expect(tabletResponsive['description'], equals('平板端响应式'));
    expect(tabletResponsive['layout'], equals('Row 布局'));
    expect(tabletResponsive['behavior'], equals('水平排列'));
    
    final desktopResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'desktop');
    expect(desktopResponsive['description'], equals('桌面端响应式'));
    expect(desktopResponsive['layout'], equals('Row 布局'));
    expect(desktopResponsive['behavior'], equals('水平排列'));
    
    // 验证页面无障碍
    final accessibility = yamlToList(homePageYaml['page_accessibility']);
    expect(accessibility.length, equals(2), reason: 'HomePage should have 2 accessibility features');
    
    final semanticLabel = accessibility.firstWhere((a) => a['name'] == 'semanticLabel');
    expect(semanticLabel['description'], equals('语义标签'));
    expect(semanticLabel['compliance'], equals('WCAG 2.1'));
    
    final keyboardNavigation = accessibility.firstWhere((a) => a['name'] == 'keyboardNavigation');
    expect(keyboardNavigation['description'], equals('键盘导航'));
    expect(keyboardNavigation['compliance'], equals('WCAG 2.1'));
    
    // 验证页面性能
    final performance = yamlToList(homePageYaml['page_performance']);
    expect(performance.length, equals(2), reason: 'HomePage should have 2 performance considerations');
    
    final buildPerformance = performance.firstWhere((p) => p['operation'] == 'build');
    expect(buildPerformance['optimization'], equals('构建优化'));
    expect(buildPerformance['description'], equals('构建性能优化'));
    
    final navigationPerformance = performance.firstWhere((p) => p['operation'] == 'navigation');
    expect(navigationPerformance['optimization'], equals('导航优化'));
    expect(navigationPerformance['description'], equals('导航性能优化'));
    
    // 验证页面测试
    final testing = yamlToList(homePageYaml['page_testing']);
    expect(testing.length, equals(1), reason: 'HomePage should have 1 testing strategy');
    
    final testHomePage = testing.firstWhere((t) => t['name'] == 'testHomePage');
    expect(testHomePage['description'], equals('测试主页'));
    expect(testHomePage['type'], equals('widget'));
    expect(testHomePage['coverage'], equals('100%'));
    expect(testHomePage['scenarios'], equals('欢迎信息、导航、响应式、无障碍'));
    
    // 验证页面依赖
    final dependencies = yamlToList(homePageYaml['page_dependencies']);
    expect(dependencies.length, equals(2), reason: 'HomePage should have 2 dependencies');
    
    final riverpodDependency = dependencies.firstWhere((d) => d['name'] == 'Riverpod');
    expect(riverpodDependency['type'], equals('状态管理'));
    expect(riverpodDependency['description'], equals('Riverpod 状态管理'));
    expect(riverpodDependency['required'], equals(true));
    
    final appLocalizationsDependency = dependencies.firstWhere((d) => d['name'] == 'AppLocalizations');
    expect(appLocalizationsDependency['type'], equals('国际化'));
    expect(appLocalizationsDependency['description'], equals('应用本地化'));
    expect(appLocalizationsDependency['required'], equals(true));
    
    // 验证页面导入
    final imports = yamlToList(homePageYaml['page_imports']);
    expect(imports.length, equals(8), reason: 'HomePage should have 8 imports');
    expect(imports, contains('package:flutter/material.dart'));
    expect(imports, contains('package:flutter_riverpod/flutter_riverpod.dart'));
    expect(imports, contains('package:granoflow/generated/l10n/app_localizations.dart'));
    
    // 验证页面分类
    final categories = yamlToMap(homePageYaml['page_categories']);
    expect(categories['main_pages'], isNotNull);
    
    final mainPages = yamlToList(categories['main_pages']);
    expect(mainPages.length, equals(1), reason: 'HomePage should have 1 main page');
    
    final homePageComponent = mainPages.firstWhere((c) => c['name'] == 'HomePage');
    expect(homePageComponent['description'], equals('主页页面'));
    expect(homePageComponent['type'], equals('ConsumerWidget'));
    expect(homePageComponent['category'], equals('main'));
    
    // 验证页面交互
    final interactions = yamlToList(homePageYaml['page_interactions']);
    expect(interactions.length, equals(1), reason: 'HomePage should have 1 interaction');
    
    final navigationTapInteraction = interactions.firstWhere((i) => i['name'] == 'navigationTap');
    expect(navigationTapInteraction['description'], equals('导航点击交互'));
    expect(navigationTapInteraction['type'], equals('tap'));
    expect(navigationTapInteraction['handler'], equals('导航处理函数'));
    expect(navigationTapInteraction['feedback'], equals('视觉反馈'));
    expect(navigationTapInteraction['accessibility'], equals('支持无障碍'));
    
    // 验证页面动画
    final animations = yamlToList(homePageYaml['page_animations']);
    expect(animations.length, equals(1), reason: 'HomePage should have 1 animation');
    
    final pageAnimation = animations.firstWhere((a) => a['name'] == 'pageAnimation');
    expect(pageAnimation['description'], equals('页面动画'));
    expect(pageAnimation['type'], equals('fade'));
    expect(pageAnimation['duration'], equals('300ms'));
    expect(pageAnimation['curve'], equals('easeInOut'));
    expect(pageAnimation['trigger'], equals('页面显示'));
    
    // 验证页面验证
    final validation = yamlToList(homePageYaml['page_validation']);
    expect(validation.length, equals(1), reason: 'HomePage should have 1 validation rule');
    
    final titleValidation = validation.firstWhere((v) => v['field'] == 'title');
    expect(titleValidation['rule'], equals('not_empty'));
    expect(titleValidation['description'], equals('标题不能为空'));
    expect(titleValidation['required'], equals(true));
    
    // 验证页面错误处理
    final errorHandling = yamlToList(homePageYaml['page_error_handling']);
    expect(errorHandling.length, equals(1), reason: 'HomePage should have 1 error handling');
    
    final navigationException = errorHandling.firstWhere((e) => e['exception'] == 'NavigationException');
    expect(navigationException['description'], equals('导航异常'));
    expect(navigationException['handling'], equals('处理导航错误并显示错误消息'));
    expect(navigationException['recovery'], equals('重试机制'));
    expect(navigationException['user_feedback'], equals('显示错误消息'));
    
    // 验证页面国际化
    final internationalization = yamlToList(homePageYaml['page_internationalization']);
    expect(internationalization.length, equals(1), reason: 'HomePage should have 1 internationalization');
    
    final homePageI18n = internationalization.firstWhere((i) => i['name'] == 'homePage');
    expect(homePageI18n['description'], equals('主页国际化'));
    expect(homePageI18n['languages'], equals('zh_CN, en_US'));
    expect(homePageI18n['fallback'], equals('en_US'));
    expect(homePageI18n['context'], equals('主页'));
    
    // 验证页面主题集成
    final themeIntegration = yamlToList(homePageYaml['page_theme_integration']);
    expect(themeIntegration.length, equals(2), reason: 'HomePage should have 2 theme integrations');
    
    final pageTheme = themeIntegration.firstWhere((t) => t['name'] == 'pageTheme');
    expect(pageTheme['description'], equals('页面主题'));
    expect(pageTheme['type'], equals('color'));
    expect(pageTheme['default_value'], equals('主题色'));
    expect(pageTheme['theme_aware'], equals(true));
    
    final textTheme = themeIntegration.firstWhere((t) => t['name'] == 'textTheme');
    expect(textTheme['description'], equals('文字主题'));
    expect(textTheme['type'], equals('text_style'));
    expect(textTheme['default_value'], equals('主题文字样式'));
    expect(textTheme['theme_aware'], equals(true));
    
    // 验证页面状态管理
    final stateManagement = yamlToList(homePageYaml['page_state_management']);
    expect(stateManagement.length, equals(1), reason: 'HomePage should have 1 state management');
    
    final riverpodStateManagement = stateManagement.firstWhere((s) => s['pattern'] == 'Riverpod 状态管理');
    expect(riverpodStateManagement['description'], equals('使用 Riverpod 管理状态'));
    expect(riverpodStateManagement['implementation'], equals('使用 ConsumerWidget'));
    expect(riverpodStateManagement['benefits'], equals('响应式、可测试'));
    expect(riverpodStateManagement['considerations'], equals('需要 Provider 配置'));
    
    // 验证页面导航
    final navigation = yamlToList(homePageYaml['page_navigation']);
    expect(navigation.length, equals(1), reason: 'HomePage should have 1 navigation');
    
    final homeNavigation = navigation.firstWhere((n) => n['name'] == 'homeNavigation');
    expect(homeNavigation['description'], equals('主页导航'));
    expect(homeNavigation['type'], equals('route'));
    expect(homeNavigation['destination'], equals('主页'));
    expect(homeNavigation['parameters'], equals('无'));
    
    // 验证页面路由
    final routing = yamlToList(homePageYaml['page_routing']);
    expect(routing.length, equals(1), reason: 'HomePage should have 1 routing');
    
    final homeRoute = routing.firstWhere((r) => r['name'] == 'homeRoute');
    expect(homeRoute['description'], equals('主页路由'));
    expect(homeRoute['path'], equals('/'));
    expect(homeRoute['parameters'], equals('无'));
    expect(homeRoute['guards'], equals('无'));
    
    // 验证页面数据流
    final dataFlow = yamlToList(homePageYaml['page_data_flow']);
    expect(dataFlow.length, equals(1), reason: 'HomePage should have 1 data flow');
    
    final seedDataFlow = dataFlow.firstWhere((d) => d['name'] == 'seedDataFlow');
    expect(seedDataFlow['description'], equals('种子数据流'));
    expect(seedDataFlow['source'], equals('种子数据服务'));
    expect(seedDataFlow['destination'], equals('应用状态'));
    expect(seedDataFlow['transformation'], equals('数据初始化'));
    
    // 验证页面业务逻辑
    final businessLogic = yamlToList(homePageYaml['page_business_logic']);
    expect(businessLogic.length, equals(1), reason: 'HomePage should have 1 business logic');
    
    final welcomeLogic = businessLogic.firstWhere((b) => b['name'] == 'welcomeLogic');
    expect(welcomeLogic['description'], equals('欢迎逻辑'));
    expect(welcomeLogic['implementation'], equals('显示欢迎信息'));
    expect(welcomeLogic['dependencies'], equals('本地化服务'));
    expect(welcomeLogic['testing'], equals('单元测试'));
    
    // 验证页面用户体验
    final userExperience = yamlToList(homePageYaml['page_user_experience']);
    expect(userExperience.length, equals(1), reason: 'HomePage should have 1 user experience');
    
    final welcomeExperience = userExperience.firstWhere((u) => u['name'] == 'welcomeExperience');
    expect(welcomeExperience['description'], equals('欢迎体验'));
    expect(welcomeExperience['implementation'], equals('友好的欢迎界面'));
    expect(welcomeExperience['benefits'], equals('提升用户体验'));
    expect(welcomeExperience['considerations'], equals('多语言支持'));
    
    // 验证页面安全
    final security = yamlToList(homePageYaml['page_security']);
    expect(security.length, equals(1), reason: 'HomePage should have 1 security');
    
    final pageSecurity = security.firstWhere((s) => s['name'] == 'pageSecurity');
    expect(pageSecurity['description'], equals('页面安全'));
    expect(pageSecurity['implementation'], equals('基础安全措施'));
    expect(pageSecurity['testing'], equals('安全测试'));
    expect(pageSecurity['compliance'], equals('基础安全标准'));
    
    // 验证页面测试策略
    final testingStrategy = yamlToMap(homePageYaml['page_testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull);
    expect(testingStrategy['widget_tests'], isNotNull);
    expect(testingStrategy['integration_tests'], isNotNull);
    expect(testingStrategy['mock_strategy'], isNotNull);
    
    final unitTests = yamlToList(testingStrategy['unit_tests']);
    expect(unitTests.length, equals(10), reason: 'HomePage should have 10 unit tests');
    
    final widgetTests = yamlToList(testingStrategy['widget_tests']);
    expect(widgetTests.length, equals(10), reason: 'HomePage should have 10 widget tests');
    
    final integrationTests = yamlToList(testingStrategy['integration_tests']);
    expect(integrationTests.length, equals(10), reason: 'HomePage should have 10 integration tests');
    
    final mockStrategy = yamlToList(testingStrategy['mock_strategy']);
    expect(mockStrategy.length, equals(3), reason: 'HomePage should have 3 mock strategies');
  }

  // 验证 InboxPage
  static void validateInboxPage() {
    // 验证 YAML 文件存在
    expect(inboxPageYaml, isNotNull, reason: 'InboxPage YAML file should exist');
    
    // 验证元数据
    expect(inboxPageYaml['meta']['name'], equals('InboxPage'));
    expect(inboxPageYaml['meta']['type'], equals('page'));
    expect(inboxPageYaml['meta']['file_path'], equals('lib/presentation/inbox/inbox_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(inboxPageYaml['page_definition']);
    expect(pageDef['name'], equals('InboxPage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer_stateful'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/inbox'));
    expect(pageDef['title'], equals('Inbox'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面类型
    final pageTypes = yamlToList(inboxPageYaml['page_types']);
    expect(pageTypes.length, equals(1), reason: 'InboxPage should have 1 page type');
    expect(pageTypes.any((type) => type['name'] == 'ConsumerStatefulWidget'), isTrue);
    
    // 验证页面状态
    final state = yamlToList(inboxPageYaml['page_state']);
    expect(state.length, equals(4), reason: 'InboxPage should have 4 states');
    
    final inputControllerState = state.firstWhere((s) => s['name'] == '_inputController');
    expect(inputControllerState['type'], equals('TextEditingController'));
    expect(inputControllerState['initial_value'], equals('TextEditingController()'));
    
    final inputFocusNodeState = state.firstWhere((s) => s['name'] == '_inputFocusNode');
    expect(inputFocusNodeState['type'], equals('FocusNode'));
    expect(inputFocusNodeState['initial_value'], equals('FocusNode()'));
    
    final isSubmittingState = state.firstWhere((s) => s['name'] == '_isSubmitting');
    expect(isSubmittingState['type'], equals('bool'));
    expect(isSubmittingState['initial_value'], equals('false'));
    
    final currentQueryState = state.firstWhere((s) => s['name'] == '_currentQuery');
    expect(currentQueryState['type'], equals('String'));
    expect(currentQueryState['initial_value'], equals('空字符串'));
    
    // 验证页面事件
    final events = yamlToList(inboxPageYaml['page_events']);
    expect(events.length, equals(2), reason: 'InboxPage should have 2 events');
    
    final onTaskSubmitEvent = events.firstWhere((e) => e['name'] == 'onTaskSubmit');
    expect(onTaskSubmitEvent['description'], equals('任务提交事件'));
    expect(onTaskSubmitEvent['trigger'], equals('用户提交任务'));
    expect(onTaskSubmitEvent['handler'], equals('任务提交处理函数'));
    expect(onTaskSubmitEvent['parameters'], equals('任务数据'));
    
    final onFilterChangeEvent = events.firstWhere((e) => e['name'] == 'onFilterChange');
    expect(onFilterChangeEvent['description'], equals('过滤器变化事件'));
    expect(onFilterChangeEvent['trigger'], equals('用户改变过滤器'));
    expect(onFilterChangeEvent['handler'], equals('过滤器处理函数'));
    expect(onFilterChangeEvent['parameters'], equals('过滤器数据'));
    
    // 验证页面导入
    final imports = yamlToList(inboxPageYaml['page_imports']);
    expect(imports.length, equals(16), reason: 'InboxPage should have 16 imports');
    expect(imports, contains('package:flutter/material.dart'));
    expect(imports, contains('package:flutter_riverpod/flutter_riverpod.dart'));
    expect(imports, contains('package:intl/intl.dart'));
  }

  // 验证 TaskListPage
  static void validateTaskListPage() {
    // 验证 YAML 文件存在
    expect(taskListPageYaml, isNotNull, reason: 'TaskListPage YAML file should exist');
    
    // 验证元数据
    expect(taskListPageYaml['meta']['name'], equals('TaskListPage'));
    expect(taskListPageYaml['meta']['type'], equals('page'));
    expect(taskListPageYaml['meta']['file_path'], equals('lib/presentation/tasks/task_list_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(taskListPageYaml['page_definition']);
    expect(pageDef['name'], equals('TaskListPage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer_stateful'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/tasks'));
    expect(pageDef['title'], equals('Tasks'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面状态
    final state = yamlToList(taskListPageYaml['page_state']);
    expect(state.length, equals(1), reason: 'TaskListPage should have 1 state');
    
    final taskListState = state.firstWhere((s) => s['name'] == '_editMode');
    expect(taskListState['type'], equals('bool'));
    expect(taskListState['initial_value'], equals('false'));
    
    // 验证页面事件
    final events = yamlToList(taskListPageYaml['page_events']);
    expect(events.length, equals(2), reason: 'TaskListPage should have 2 events');
    
    final onEditModeToggleEvent = events.firstWhere((e) => e['name'] == 'onEditModeToggle');
    expect(onEditModeToggleEvent['description'], equals('编辑模式切换事件'));
    expect(onEditModeToggleEvent['trigger'], equals('用户切换编辑模式'));
    expect(onEditModeToggleEvent['handler'], equals('编辑模式处理函数'));
    expect(onEditModeToggleEvent['parameters'], equals('编辑状态'));
    
    final onTaskActionEvent = events.firstWhere((e) => e['name'] == 'onTaskAction');
    expect(onTaskActionEvent['description'], equals('任务操作事件'));
    expect(onTaskActionEvent['trigger'], equals('用户执行任务操作'));
    expect(onTaskActionEvent['handler'], equals('任务操作处理函数'));
    expect(onTaskActionEvent['parameters'], equals('操作类型'));
  }

  // 验证 TimerPage
  static void validateTimerPage() {
    // 验证 YAML 文件存在
    expect(timerPageYaml, isNotNull, reason: 'TimerPage YAML file should exist');
    
    // 验证元数据
    expect(timerPageYaml['meta']['name'], equals('TimerPage'));
    expect(timerPageYaml['meta']['type'], equals('page'));
    expect(timerPageYaml['meta']['file_path'], equals('lib/presentation/timer/timer_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(timerPageYaml['page_definition']);
    expect(pageDef['name'], equals('TimerPage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer_stateful'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/timer'));
    expect(pageDef['title'], equals('Timer'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面状态
    final state = yamlToList(timerPageYaml['page_state']);
    expect(state.length, equals(3), reason: 'TimerPage should have 3 states');
    
    final selectedTaskState = state.firstWhere((s) => s['name'] == '_selectedTask');
    expect(selectedTaskState['type'], equals('Task?'));
    expect(selectedTaskState['initial_value'], equals('null'));
    
    final templateQueryState = state.firstWhere((s) => s['name'] == '_templateQuery');
    expect(templateQueryState['type'], equals('String'));
    expect(templateQueryState['initial_value'], equals('空字符串'));
    
    final startLoadingState = state.firstWhere((s) => s['name'] == '_startLoading');
    expect(startLoadingState['type'], equals('bool'));
    expect(startLoadingState['initial_value'], equals('false'));
    
    // 验证页面事件
    final events = yamlToList(timerPageYaml['page_events']);
    expect(events.length, equals(2), reason: 'TimerPage should have 2 events');
    
    final onTimerStartEvent = events.firstWhere((e) => e['name'] == 'onTimerStart');
    expect(onTimerStartEvent['description'], equals('计时器启动事件'));
    expect(onTimerStartEvent['trigger'], equals('用户启动计时器'));
    expect(onTimerStartEvent['handler'], equals('计时器启动处理函数'));
    expect(onTimerStartEvent['parameters'], equals('任务数据'));
    
    final onTimerStopEvent = events.firstWhere((e) => e['name'] == 'onTimerStop');
    expect(onTimerStopEvent['description'], equals('计时器停止事件'));
    expect(onTimerStopEvent['trigger'], equals('用户停止计时器'));
    expect(onTimerStopEvent['handler'], equals('计时器停止处理函数'));
    expect(onTimerStopEvent['parameters'], equals('会话数据'));
  }

  // 验证 CompletedPage
  static void validateCompletedPage() {
    // 验证 YAML 文件存在
    expect(completedPageYaml, isNotNull, reason: 'CompletedPage YAML file should exist');
    
    // 验证元数据
    expect(completedPageYaml['meta']['name'], equals('CompletedPage'));
    expect(completedPageYaml['meta']['type'], equals('page'));
    expect(completedPageYaml['meta']['file_path'], equals('lib/presentation/completion_management/completed_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(completedPageYaml['page_definition']);
    expect(pageDef['name'], equals('CompletedPage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/completed'));
    expect(pageDef['title'], equals('Completed'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面状态
    final state = yamlToList(completedPageYaml['page_state']);
    expect(state.length, equals(1), reason: 'CompletedPage should have 1 state');
    
    final completedState = state.firstWhere((s) => s['name'] == 'tabController');
    expect(completedState['type'], equals('TabController'));
    expect(completedState['initial_value'], equals('TabController(length: 2)'));
    
    // 验证页面事件
    final events = yamlToList(completedPageYaml['page_events']);
    expect(events.length, equals(2), reason: 'CompletedPage should have 2 events');
    
    final onTaskReactivateEvent = events.firstWhere((e) => e['name'] == 'onTaskReactivate');
    expect(onTaskReactivateEvent['description'], equals('任务重新激活事件'));
    expect(onTaskReactivateEvent['trigger'], equals('用户重新激活任务'));
    expect(onTaskReactivateEvent['handler'], equals('任务重新激活处理函数'));
    expect(onTaskReactivateEvent['parameters'], equals('任务数据'));
    
    final onTaskArchiveEvent = events.firstWhere((e) => e['name'] == 'onTaskArchive');
    expect(onTaskArchiveEvent['description'], equals('任务归档事件'));
    expect(onTaskArchiveEvent['trigger'], equals('用户归档任务'));
    expect(onTaskArchiveEvent['handler'], equals('任务归档处理函数'));
    expect(onTaskArchiveEvent['parameters'], equals('任务数据'));
  }

  // 验证 TrashPage
  static void validateTrashPage() {
    // 验证 YAML 文件存在
    expect(trashPageYaml, isNotNull, reason: 'TrashPage YAML file should exist');
    
    // 验证元数据
    expect(trashPageYaml['meta']['name'], equals('TrashPage'));
    expect(trashPageYaml['meta']['type'], equals('page'));
    expect(trashPageYaml['meta']['file_path'], equals('lib/presentation/completion_management/trash_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(trashPageYaml['page_definition']);
    expect(pageDef['name'], equals('TrashPage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/trash'));
    expect(pageDef['title'], equals('Trash'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面状态
    final state = yamlToList(trashPageYaml['page_state']);
    expect(state.length, equals(1), reason: 'TrashPage should have 1 state');
    
    final trashState = state.firstWhere((s) => s['name'] == 'tasksAsync');
    expect(trashState['type'], equals('AsyncValue<List<Task>>'));
    expect(trashState['initial_value'], equals('AsyncValue.loading()'));
    
    // 验证页面事件
    final events = yamlToList(trashPageYaml['page_events']);
    expect(events.length, equals(2), reason: 'TrashPage should have 2 events');
    
    final onTaskRestoreEvent = events.firstWhere((e) => e['name'] == 'onTaskRestore');
    expect(onTaskRestoreEvent['description'], equals('任务恢复事件'));
    expect(onTaskRestoreEvent['trigger'], equals('用户恢复任务'));
    expect(onTaskRestoreEvent['handler'], equals('任务恢复处理函数'));
    expect(onTaskRestoreEvent['parameters'], equals('任务数据'));
    
    final onTaskDeleteEvent = events.firstWhere((e) => e['name'] == 'onTaskDelete');
    expect(onTaskDeleteEvent['description'], equals('任务永久删除事件'));
    expect(onTaskDeleteEvent['trigger'], equals('用户永久删除任务'));
    expect(onTaskDeleteEvent['handler'], equals('任务删除处理函数'));
    expect(onTaskDeleteEvent['parameters'], equals('任务数据'));
  }

  // 验证 AchievementsPage
  static void validateAchievementsPage() {
    // 验证 YAML 文件存在
    expect(achievementsPageYaml, isNotNull, reason: 'AchievementsPage YAML file should exist');
    
    // 验证元数据
    expect(achievementsPageYaml['meta']['name'], equals('AchievementsPage'));
    expect(achievementsPageYaml['meta']['type'], equals('page'));
    expect(achievementsPageYaml['meta']['file_path'], equals('lib/presentation/achievements/achievements_page.dart'));
    
    // 验证页面定义
    final pageDef = yamlToMap(achievementsPageYaml['page_definition']);
    expect(pageDef['name'], equals('AchievementsPage'));
    expect(pageDef['layer'], equals('presentation'));
    expect(pageDef['pattern'], equals('consumer'));
    expect(pageDef['category'], equals('main'));
    expect(pageDef['route'], equals('/achievements'));
    expect(pageDef['title'], equals('Achievements'));
    expect(pageDef['reusable'], equals(true));
    
    // 验证页面状态
    final state = yamlToList(achievementsPageYaml['page_state']);
    expect(state.length, equals(1), reason: 'AchievementsPage should have 1 state');
    
    final achievementsState = state.firstWhere((s) => s['name'] == 'comingSoon');
    expect(achievementsState['type'], equals('bool'));
    expect(achievementsState['initial_value'], equals('true'));
    
    // 验证页面事件
    final events = yamlToList(achievementsPageYaml['page_events']);
    expect(events.length, equals(1), reason: 'AchievementsPage should have 1 event');
    
    final onComingSoonEvent = events.firstWhere((e) => e['name'] == 'onComingSoon');
    expect(onComingSoonEvent['description'], equals('即将推出事件'));
    expect(onComingSoonEvent['trigger'], equals('页面显示'));
    expect(onComingSoonEvent['handler'], equals('即将推出处理函数'));
    expect(onComingSoonEvent['parameters'], equals('无'));
  }

  // 验证所有页面的一致性
  static void validateAllPagesConsistency() {
    // 验证所有页面都有基本结构
    final pages = [homePageYaml, inboxPageYaml, taskListPageYaml, timerPageYaml, completedPageYaml, trashPageYaml, achievementsPageYaml];
    
    for (final page in pages) {
      expect(page, isNotNull, reason: 'Page YAML should exist');
      expect(page['meta'], isNotNull, reason: 'Page should have meta information');
      expect(page['page_definition'], isNotNull, reason: 'Page should have page definition');
      expect(page['page_types'], isNotNull, reason: 'Page should have page types');
      expect(page['page_state'], isNotNull, reason: 'Page should have page state');
      expect(page['page_events'], isNotNull, reason: 'Page should have page events');
      expect(page['page_imports'], isNotNull, reason: 'Page should have page imports');
    }
  }
}

void main() {
  group('Pages YAML Tests', () {
    setUpAll(() async {
      await PagesYAMLTest.loadYAMLFiles();
    });

    test('HomePage YAML validation', () {
      PagesYAMLTest.validateHomePage();
    });

    test('InboxPage YAML validation', () {
      PagesYAMLTest.validateInboxPage();
    });

    test('TaskListPage YAML validation', () {
      PagesYAMLTest.validateTaskListPage();
    });

    test('TimerPage YAML validation', () {
      PagesYAMLTest.validateTimerPage();
    });

    test('CompletedPage YAML validation', () {
      PagesYAMLTest.validateCompletedPage();
    });

    test('TrashPage YAML validation', () {
      PagesYAMLTest.validateTrashPage();
    });

    test('AchievementsPage YAML validation', () {
      PagesYAMLTest.validateAchievementsPage();
    });

    test('All pages consistency validation', () {
      PagesYAMLTest.validateAllPagesConsistency();
    });
  });
}