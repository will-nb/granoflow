import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:flutter_test/flutter_test.dart';
import 'yaml_test_helper.dart';

class WidgetsYAMLTest {
  static late Map<String, dynamic> chipToggleGroupYaml;
  static late Map<String, dynamic> createTaskDialogYaml;
  static late Map<String, dynamic> mainDrawerYaml;
  static late Map<String, dynamic> pageAppBarYaml;

  static Future<void> loadYAMLFiles() async {
    chipToggleGroupYaml = Map<String, dynamic>.from(loadYaml(await File('documents/architecture/widgets/chip_toggle_group.yaml').readAsString()) as Map);
    createTaskDialogYaml = Map<String, dynamic>.from(loadYaml(await File('documents/architecture/widgets/create_task_dialog.yaml').readAsString()) as Map);
    mainDrawerYaml = Map<String, dynamic>.from(loadYaml(await File('documents/architecture/widgets/main_drawer.yaml').readAsString()) as Map);
    pageAppBarYaml = Map<String, dynamic>.from(loadYaml(await File('documents/architecture/widgets/page_app_bar.yaml').readAsString()) as Map);
  }

  // 验证 ChipToggleGroup
  static void validateChipToggleGroup() {
    // 验证 YAML 文件存在
    expect(chipToggleGroupYaml, isNotNull, reason: 'ChipToggleGroup YAML file should exist');
    
    // 验证元数据
    expect(chipToggleGroupYaml['meta']['name'], equals('ChipToggleGroup'));
    expect(chipToggleGroupYaml['meta']['type'], equals('widget'));
    expect(chipToggleGroupYaml['meta']['file_path'], equals('lib/presentation/widgets/chip_toggle_group.dart'));
    
    // 验证 Widget 定义
    final widgetDef = yamlToMap(chipToggleGroupYaml['widget_definition']);
    expect(widgetDef['name'], equals('ChipToggleGroup'));
    expect(widgetDef['layer'], equals('presentation'));
    expect(widgetDef['pattern'], equals('stateless'));
    expect(widgetDef['category'], equals('ui_component'));
    expect(widgetDef['reusable'], equals(true));
    
    // 验证 Widget 类型
    final widgetTypes = yamlToList(chipToggleGroupYaml['widget_types']);
    expect(widgetTypes.length, equals(1), reason: 'ChipToggleGroup should have 1 widget type');
    expect(widgetTypes.any((type) => type['name'] == 'StatelessWidget'), isTrue);
    
    // 验证 Widget 属性
    final properties = yamlToList(chipToggleGroupYaml['widget_properties']);
    expect(properties.length, equals(6), reason: 'ChipToggleGroup should have 6 properties');
    
    final optionsProperty = properties.firstWhere((p) => p['name'] == 'options');
    expect(optionsProperty['type'], equals('List<ChipToggleOption>'));
    expect(optionsProperty['required'], equals(true));
    
    final selectedValuesProperty = properties.firstWhere((p) => p['name'] == 'selectedValues');
    expect(selectedValuesProperty['type'], equals('Set<String>'));
    expect(selectedValuesProperty['required'], equals(true));
    
    final onSelectionChangedProperty = properties.firstWhere((p) => p['name'] == 'onSelectionChanged');
    expect(onSelectionChangedProperty['type'], equals('ValueChanged<Set<String>>'));
    expect(onSelectionChangedProperty['required'], equals(true));
    
    final multiSelectProperty = properties.firstWhere((p) => p['name'] == 'multiSelect');
    expect(multiSelectProperty['type'], equals('bool'));
    expect(multiSelectProperty['required'], equals(false));
    expect(multiSelectProperty['default_value'], equals('false'));
    
    final spacingProperty = properties.firstWhere((p) => p['name'] == 'spacing');
    expect(spacingProperty['type'], equals('double'));
    expect(spacingProperty['required'], equals(false));
    expect(spacingProperty['default_value'], equals('8'));
    
    final runSpacingProperty = properties.firstWhere((p) => p['name'] == 'runSpacing');
    expect(runSpacingProperty['type'], equals('double'));
    expect(runSpacingProperty['required'], equals(false));
    expect(runSpacingProperty['default_value'], equals('8'));
    
    // 验证 Widget 方法
    final methods = yamlToList(chipToggleGroupYaml['widget_methods']);
    expect(methods.length, equals(2), reason: 'ChipToggleGroup should have 2 methods');
    
    final buildMethod = methods.firstWhere((m) => m['name'] == 'build');
    expect(buildMethod['return_type'], equals('Widget'));
    expect(buildMethod['parameters'].length, equals(1));
    
    final handleTapMethod = methods.firstWhere((m) => m['name'] == '_handleTap');
    expect(handleTapMethod['return_type'], equals('void'));
    expect(handleTapMethod['parameters'].length, equals(2));
    expect(handleTapMethod['visibility'], equals('private'));
    
    // 验证 Widget 状态
    final state = yamlToList(chipToggleGroupYaml['widget_state']);
    expect(state.length, equals(1), reason: 'ChipToggleGroup should have 1 state');
    
    final selectedValuesState = state.firstWhere((s) => s['name'] == 'selectedValues');
    expect(selectedValuesState['type'], equals('Set<String>'));
    expect(selectedValuesState['initial_value'], equals('空集合'));
    
    // 验证 Widget 事件
    final events = yamlToList(chipToggleGroupYaml['widget_events']);
    expect(events.length, equals(1), reason: 'ChipToggleGroup should have 1 event');
    
    final onSelectionChangedEvent = events.firstWhere((e) => e['name'] == 'onSelectionChanged');
    expect(onSelectionChangedEvent['description'], equals('选择变化事件'));
    expect(onSelectionChangedEvent['trigger'], equals('用户点击芯片'));
    expect(onSelectionChangedEvent['handler'], equals('_handleTap'));
    
    // 验证 Widget 样式
    final styling = yamlToList(chipToggleGroupYaml['widget_styling']);
    expect(styling.length, equals(1), reason: 'ChipToggleGroup should have 1 styling');
    
    final chipStyle = styling.firstWhere((s) => s['name'] == 'chipStyle');
    expect(chipStyle['description'], equals('芯片样式'));
    expect(chipStyle['responsive'], equals(false));
    expect(chipStyle['theme_aware'], equals(true));
    
    // 验证 Widget 响应式
    final responsive = yamlToList(chipToggleGroupYaml['widget_responsive']);
    expect(responsive.length, equals(3), reason: 'ChipToggleGroup should have 3 responsive breakpoints');
    
    final mobileResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'mobile');
    expect(mobileResponsive['description'], equals('移动端响应式'));
    expect(mobileResponsive['layout'], equals('Wrap 布局'));
    expect(mobileResponsive['behavior'], equals('自动换行'));
    
    final tabletResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'tablet');
    expect(tabletResponsive['description'], equals('平板端响应式'));
    expect(tabletResponsive['layout'], equals('Wrap 布局'));
    expect(tabletResponsive['behavior'], equals('自动换行'));
    
    final desktopResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'desktop');
    expect(desktopResponsive['description'], equals('桌面端响应式'));
    expect(desktopResponsive['layout'], equals('Wrap 布局'));
    expect(desktopResponsive['behavior'], equals('自动换行'));
    
    // 验证 Widget 无障碍
    final accessibility = yamlToList(chipToggleGroupYaml['widget_accessibility']);
    expect(accessibility.length, equals(2), reason: 'ChipToggleGroup should have 2 accessibility features');
    
    final semanticLabel = accessibility.firstWhere((a) => a['name'] == 'semanticLabel');
    expect(semanticLabel['description'], equals('语义标签'));
    expect(semanticLabel['compliance'], equals('WCAG 2.1'));
    
    final keyboardNavigation = accessibility.firstWhere((a) => a['name'] == 'keyboardNavigation');
    expect(keyboardNavigation['description'], equals('键盘导航'));
    expect(keyboardNavigation['compliance'], equals('WCAG 2.1'));
    
    // 验证 Widget 性能
    final performance = yamlToList(chipToggleGroupYaml['widget_performance']);
    expect(performance.length, equals(2), reason: 'ChipToggleGroup should have 2 performance considerations');
    
    final buildPerformance = performance.firstWhere((p) => p['operation'] == 'build');
    expect(buildPerformance['optimization'], equals('构建优化'));
    expect(buildPerformance['description'], equals('构建性能优化'));
    
    final selectionPerformance = performance.firstWhere((p) => p['operation'] == 'selection');
    expect(selectionPerformance['optimization'], equals('选择优化'));
    expect(selectionPerformance['description'], equals('选择性能优化'));
    
    // 验证 Widget 测试
    final testing = yamlToList(chipToggleGroupYaml['widget_testing']);
    expect(testing.length, equals(1), reason: 'ChipToggleGroup should have 1 testing strategy');
    
    final testChipToggleGroup = testing.firstWhere((t) => t['name'] == 'testChipToggleGroup');
    expect(testChipToggleGroup['description'], equals('测试芯片切换组'));
    expect(testChipToggleGroup['type'], equals('widget'));
    expect(testChipToggleGroup['coverage'], equals('100%'));
    expect(testChipToggleGroup['scenarios'], equals('单选、多选、间距、响应式'));
    
    // 验证 Widget 依赖
    final dependencies = yamlToList(chipToggleGroupYaml['widget_dependencies']);
    expect(dependencies.length, equals(1), reason: 'ChipToggleGroup should have 1 dependency');
    
    final chipToggleOptionDependency = dependencies.firstWhere((d) => d['name'] == 'ChipToggleOption');
    expect(chipToggleOptionDependency['type'], equals('数据模型'));
    expect(chipToggleOptionDependency['description'], equals('芯片选项数据模型'));
    expect(chipToggleOptionDependency['required'], equals(true));
    
    // 验证 Widget 导入
    final imports = yamlToList(chipToggleGroupYaml['widget_imports']);
    expect(imports.length, equals(1), reason: 'ChipToggleGroup should have 1 import');
    expect(imports, contains('package:flutter/material.dart'));
    
    // 验证 Widget 分类
    final categories = yamlToMap(chipToggleGroupYaml['widget_categories']);
    expect(categories['ui_components'], isNotNull);
    
    final uiComponents = yamlToList(categories['ui_components']);
    expect(uiComponents.length, equals(1), reason: 'ChipToggleGroup should have 1 UI component');
    
    final chipToggleGroupComponent = uiComponents.firstWhere((c) => c['name'] == 'ChipToggleGroup');
    expect(chipToggleGroupComponent['description'], equals('芯片切换组组件'));
    expect(chipToggleGroupComponent['type'], equals('StatelessWidget'));
    expect(chipToggleGroupComponent['category'], equals('ui_component'));
    
    // 验证 Widget 交互
    final interactions = yamlToList(chipToggleGroupYaml['widget_interactions']);
    expect(interactions.length, equals(1), reason: 'ChipToggleGroup should have 1 interaction');
    
    final chipTapInteraction = interactions.firstWhere((i) => i['name'] == 'chipTap');
    expect(chipTapInteraction['description'], equals('芯片点击交互'));
    expect(chipTapInteraction['type'], equals('tap'));
    expect(chipTapInteraction['handler'], equals('_handleTap'));
    expect(chipTapInteraction['feedback'], equals('视觉反馈'));
    expect(chipTapInteraction['accessibility'], equals('支持无障碍'));
    
    // 验证 Widget 动画
    final animations = yamlToList(chipToggleGroupYaml['widget_animations']);
    expect(animations.length, equals(1), reason: 'ChipToggleGroup should have 1 animation');
    
    final selectionAnimation = animations.firstWhere((a) => a['name'] == 'selectionAnimation');
    expect(selectionAnimation['description'], equals('选择动画'));
    expect(selectionAnimation['type'], equals('scale'));
    expect(selectionAnimation['duration'], equals('200ms'));
    expect(selectionAnimation['curve'], equals('easeInOut'));
    expect(selectionAnimation['trigger'], equals('选择变化'));
    
    // 验证 Widget 验证
    final validation = yamlToList(chipToggleGroupYaml['widget_validation']);
    expect(validation.length, equals(4), reason: 'ChipToggleGroup should have 4 validation rules');
    
    final optionsValidation = validation.firstWhere((v) => v['field'] == 'options');
    expect(optionsValidation['rule'], equals('not_empty'));
    expect(optionsValidation['description'], equals('选项列表不能为空'));
    expect(optionsValidation['required'], equals(true));
    
    final selectedValuesValidation = validation.firstWhere((v) => v['field'] == 'selectedValues');
    expect(selectedValuesValidation['rule'], equals('not_null'));
    expect(selectedValuesValidation['description'], equals('选中值不能为 null'));
    expect(selectedValuesValidation['required'], equals(true));
    
    final spacingValidation = validation.firstWhere((v) => v['field'] == 'spacing');
    expect(spacingValidation['rule'], equals('non_negative'));
    expect(spacingValidation['description'], equals('间距不能为负数'));
    expect(spacingValidation['required'], equals(false));
    
    final runSpacingValidation = validation.firstWhere((v) => v['field'] == 'runSpacing');
    expect(runSpacingValidation['rule'], equals('non_negative'));
    expect(runSpacingValidation['description'], equals('行间距不能为负数'));
    expect(runSpacingValidation['required'], equals(false));
    
    // 验证 Widget 错误处理
    final errorHandling = yamlToList(chipToggleGroupYaml['widget_error_handling']);
    expect(errorHandling.length, equals(1), reason: 'ChipToggleGroup should have 1 error handling');
    
    final argumentError = errorHandling.firstWhere((e) => e['exception'] == 'ArgumentError');
    expect(argumentError['description'], equals('参数错误'));
    expect(argumentError['handling'], equals('验证参数并抛出描述性错误'));
    expect(argumentError['recovery'], equals('提供参数修正建议'));
    expect(argumentError['user_feedback'], equals('显示错误消息'));
    
    // 验证 Widget 国际化
    final internationalization = yamlToList(chipToggleGroupYaml['widget_internationalization']);
    expect(internationalization.length, equals(1), reason: 'ChipToggleGroup should have 1 internationalization');
    
    final chipToggleGroupI18n = internationalization.firstWhere((i) => i['name'] == 'chipToggleGroup');
    expect(chipToggleGroupI18n['description'], equals('芯片切换组国际化'));
    expect(chipToggleGroupI18n['languages'], equals('zh_CN, en_US'));
    expect(chipToggleGroupI18n['fallback'], equals('en_US'));
    expect(chipToggleGroupI18n['context'], equals('UI 组件'));
    
    // 验证 Widget 主题集成
    final themeIntegration = yamlToList(chipToggleGroupYaml['widget_theme_integration']);
    expect(themeIntegration.length, equals(2), reason: 'ChipToggleGroup should have 2 theme integrations');
    
    final chipTheme = themeIntegration.firstWhere((t) => t['name'] == 'chipTheme');
    expect(chipTheme['description'], equals('芯片主题'));
    expect(chipTheme['type'], equals('color'));
    expect(chipTheme['default_value'], equals('主题色'));
    expect(chipTheme['theme_aware'], equals(true));
    
    final spacingTheme = themeIntegration.firstWhere((t) => t['name'] == 'spacingTheme');
    expect(spacingTheme['description'], equals('间距主题'));
    expect(spacingTheme['type'], equals('double'));
    expect(spacingTheme['default_value'], equals('8'));
    expect(spacingTheme['theme_aware'], equals(false));
    
    // 验证 Widget 状态管理
    final stateManagement = yamlToList(chipToggleGroupYaml['widget_state_management']);
    expect(stateManagement.length, equals(1), reason: 'ChipToggleGroup should have 1 state management');
    
    final externalStateManagement = stateManagement.firstWhere((s) => s['pattern'] == '外部状态管理');
    expect(externalStateManagement['description'], equals('通过回调管理状态'));
    expect(externalStateManagement['implementation'], equals('使用 ValueChanged 回调'));
    expect(externalStateManagement['benefits'], equals('解耦、可复用'));
    expect(externalStateManagement['considerations'], equals('需要外部状态管理'));
    
    // 验证 Widget 测试策略
    final testingStrategy = yamlToMap(chipToggleGroupYaml['widget_testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull);
    expect(testingStrategy['widget_tests'], isNotNull);
    expect(testingStrategy['integration_tests'], isNotNull);
    expect(testingStrategy['mock_strategy'], isNotNull);
    
    final unitTests = yamlToList(testingStrategy['unit_tests']);
    expect(unitTests.length, equals(10), reason: 'ChipToggleGroup should have 10 unit tests');
    
    final widgetTests = yamlToList(testingStrategy['widget_tests']);
    expect(widgetTests.length, equals(10), reason: 'ChipToggleGroup should have 10 widget tests');
    
    final integrationTests = yamlToList(testingStrategy['integration_tests']);
    expect(integrationTests.length, equals(10), reason: 'ChipToggleGroup should have 10 integration tests');
    
    final mockStrategy = yamlToList(testingStrategy['mock_strategy']);
    expect(mockStrategy.length, equals(3), reason: 'ChipToggleGroup should have 3 mock strategies');
    
    final mockChipToggleGroup = mockStrategy.firstWhere((m) => m['name'] == 'MockChipToggleGroup');
    expect(mockChipToggleGroup['description'], equals('Mock 实现用于测试'));
    
    final fakeChipToggleGroup = mockStrategy.firstWhere((m) => m['name'] == 'FakeChipToggleGroup');
    expect(fakeChipToggleGroup['description'], equals('Fake 实现用于测试'));
    
    final testChipToggleGroupMock = mockStrategy.firstWhere((m) => m['name'] == 'TestChipToggleGroup');
    expect(testChipToggleGroupMock['description'], equals('测试专用 Widget'));
  }

  // 验证 CreateTaskDialog
  static void validateCreateTaskDialog() {
    expect(createTaskDialogYaml, isNotNull, reason: 'CreateTaskDialog YAML file should exist');
    
    final widgetDef = yamlToMap(createTaskDialogYaml['widget_definition']);
    expect(widgetDef['name'], equals('CreateTaskDialog'));
    expect(widgetDef['layer'], equals('presentation'));
    expect(widgetDef['pattern'], equals('consumer_stateful'));
    expect(widgetDef['category'], equals('dialog'));
    expect(widgetDef['reusable'], equals(true));
    
    // 验证 Widget 类型
    final widgetTypes = yamlToList(createTaskDialogYaml['widget_types']);
    expect(widgetTypes.length, equals(1), reason: 'CreateTaskDialog should have 1 widget type');
    expect(widgetTypes.any((type) => type['name'] == 'ConsumerStatefulWidget'), isTrue);
    
    // 验证 Widget 属性
    final properties = yamlToList(createTaskDialogYaml['widget_properties']);
    expect(properties.length, equals(1), reason: 'CreateTaskDialog should have 1 property');
    
    final keyProperty = properties.firstWhere((p) => p['name'] == 'key');
    expect(keyProperty['type'], equals('Key?'));
    expect(keyProperty['required'], equals(false));
    
    // 验证 Widget 方法
    final methods = yamlToList(createTaskDialogYaml['widget_methods']);
    expect(methods.length, equals(3), reason: 'CreateTaskDialog should have 3 methods');
    
    final createStateMethod = methods.firstWhere((m) => m['name'] == 'createState');
    expect(createStateMethod['return_type'], equals('ConsumerState<CreateTaskDialog>'));
    expect(createStateMethod['parameters'].length, equals(0));
    
    final buildMethod = methods.firstWhere((m) => m['name'] == 'build');
    expect(buildMethod['return_type'], equals('Widget'));
    expect(buildMethod['parameters'].length, equals(1));
    
    final disposeMethod = methods.firstWhere((m) => m['name'] == 'dispose');
    expect(disposeMethod['return_type'], equals('void'));
    expect(disposeMethod['parameters'].length, equals(0));
    
    // 验证 Widget 状态
    final state = yamlToList(createTaskDialogYaml['widget_state']);
    expect(state.length, equals(5), reason: 'CreateTaskDialog should have 5 states');
    
    final titleControllerState = state.firstWhere((s) => s['name'] == '_titleController');
    expect(titleControllerState['type'], equals('TextEditingController'));
    expect(titleControllerState['initial_value'], equals('TextEditingController()'));
    
    final selectedTagState = state.firstWhere((s) => s['name'] == '_selectedTag');
    expect(selectedTagState['type'], equals('String'));
    expect(selectedTagState['initial_value'], equals("'工作'"));
    
    final selectedParentState = state.firstWhere((s) => s['name'] == '_selectedParent');
    expect(selectedParentState['type'], equals('String'));
    expect(selectedParentState['initial_value'], equals("'根任务'"));
    
    final availableTagsState = state.firstWhere((s) => s['name'] == '_availableTags');
    expect(availableTagsState['type'], equals('List<String>'));
    expect(availableTagsState['initial_value'], equals("['工作', '学习', '生活', '娱乐']"));
    
    final availableParentsState = state.firstWhere((s) => s['name'] == '_availableParents');
    expect(availableParentsState['type'], equals('List<String>'));
    expect(availableParentsState['initial_value'], equals("['根任务', '项目A', '项目B']"));
    
    // 验证 Widget 事件
    final events = yamlToList(createTaskDialogYaml['widget_events']);
    expect(events.length, equals(2), reason: 'CreateTaskDialog should have 2 events');
    
    final onCreateTaskEvent = events.firstWhere((e) => e['name'] == 'onCreateTask');
    expect(onCreateTaskEvent['description'], equals('创建任务事件'));
    expect(onCreateTaskEvent['trigger'], equals('用户点击创建按钮'));
    expect(onCreateTaskEvent['handler'], equals('创建任务处理函数'));
    expect(onCreateTaskEvent['parameters'], equals('任务数据'));
    
    final onCancelEvent = events.firstWhere((e) => e['name'] == 'onCancel');
    expect(onCancelEvent['description'], equals('取消事件'));
    expect(onCancelEvent['trigger'], equals('用户点击取消按钮'));
    expect(onCancelEvent['handler'], equals('取消处理函数'));
    expect(onCancelEvent['parameters'], equals('无'));
    
    // 验证 Widget 样式
    final styling = yamlToList(createTaskDialogYaml['widget_styling']);
    expect(styling.length, equals(1), reason: 'CreateTaskDialog should have 1 styling');
    
    final dialogStyle = styling.firstWhere((s) => s['name'] == 'dialogStyle');
    expect(dialogStyle['description'], equals('对话框样式'));
    expect(dialogStyle['responsive'], equals(true));
    expect(dialogStyle['theme_aware'], equals(true));
    
    // 验证 Widget 响应式
    final responsive = yamlToList(createTaskDialogYaml['widget_responsive']);
    expect(responsive.length, equals(3), reason: 'CreateTaskDialog should have 3 responsive breakpoints');
    
    final mobileResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'mobile');
    expect(mobileResponsive['description'], equals('移动端响应式'));
    expect(mobileResponsive['layout'], equals('Column 布局'));
    expect(mobileResponsive['behavior'], equals('垂直排列'));
    
    final tabletResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'tablet');
    expect(tabletResponsive['description'], equals('平板端响应式'));
    expect(tabletResponsive['layout'], equals('Column 布局'));
    expect(tabletResponsive['behavior'], equals('垂直排列'));
    
    final desktopResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'desktop');
    expect(desktopResponsive['description'], equals('桌面端响应式'));
    expect(desktopResponsive['layout'], equals('Column 布局'));
    expect(desktopResponsive['behavior'], equals('垂直排列'));
    
    // 验证 Widget 无障碍
    final accessibility = yamlToList(createTaskDialogYaml['widget_accessibility']);
    expect(accessibility.length, equals(2), reason: 'CreateTaskDialog should have 2 accessibility features');
    
    final semanticLabel = accessibility.firstWhere((a) => a['name'] == 'semanticLabel');
    expect(semanticLabel['description'], equals('语义标签'));
    expect(semanticLabel['compliance'], equals('WCAG 2.1'));
    
    final keyboardNavigation = accessibility.firstWhere((a) => a['name'] == 'keyboardNavigation');
    expect(keyboardNavigation['description'], equals('键盘导航'));
    expect(keyboardNavigation['compliance'], equals('WCAG 2.1'));
    
    // 验证 Widget 性能
    final performance = yamlToList(createTaskDialogYaml['widget_performance']);
    expect(performance.length, equals(2), reason: 'CreateTaskDialog should have 2 performance considerations');
    
    final buildPerformance = performance.firstWhere((p) => p['operation'] == 'build');
    expect(buildPerformance['optimization'], equals('构建优化'));
    expect(buildPerformance['description'], equals('构建性能优化'));
    
    final formSubmissionPerformance = performance.firstWhere((p) => p['operation'] == 'formSubmission');
    expect(formSubmissionPerformance['optimization'], equals('表单提交优化'));
    expect(formSubmissionPerformance['description'], equals('表单提交性能优化'));
    
    // 验证 Widget 测试
    final testing = yamlToList(createTaskDialogYaml['widget_testing']);
    expect(testing.length, equals(1), reason: 'CreateTaskDialog should have 1 testing strategy');
    
    final testCreateTaskDialog = testing.firstWhere((t) => t['name'] == 'testCreateTaskDialog');
    expect(testCreateTaskDialog['description'], equals('测试创建任务对话框'));
    expect(testCreateTaskDialog['type'], equals('widget'));
    expect(testCreateTaskDialog['coverage'], equals('100%'));
    expect(testCreateTaskDialog['scenarios'], equals('表单输入、提交、取消、验证'));
    
    // 验证 Widget 依赖
    final dependencies = yamlToList(createTaskDialogYaml['widget_dependencies']);
    expect(dependencies.length, equals(1), reason: 'CreateTaskDialog should have 1 dependency');
    
    final riverpodDependency = dependencies.firstWhere((d) => d['name'] == 'Riverpod');
    expect(riverpodDependency['type'], equals('状态管理'));
    expect(riverpodDependency['description'], equals('Riverpod 状态管理'));
    expect(riverpodDependency['required'], equals(true));
    
    // 验证 Widget 导入
    final imports = yamlToList(createTaskDialogYaml['widget_imports']);
    expect(imports.length, equals(2), reason: 'CreateTaskDialog should have 2 imports');
    expect(imports, contains('package:flutter/material.dart'));
    expect(imports, contains('package:flutter_riverpod/flutter_riverpod.dart'));
    
    // 验证 Widget 分类
    final categories = yamlToMap(createTaskDialogYaml['widget_categories']);
    expect(categories['dialogs'], isNotNull);
    
    final dialogs = yamlToList(categories['dialogs']);
    expect(dialogs.length, equals(1), reason: 'CreateTaskDialog should have 1 dialog');
    
    final createTaskDialogComponent = dialogs.firstWhere((c) => c['name'] == 'CreateTaskDialog');
    expect(createTaskDialogComponent['description'], equals('创建任务对话框'));
    expect(createTaskDialogComponent['type'], equals('ConsumerStatefulWidget'));
    expect(createTaskDialogComponent['category'], equals('dialog'));
    
    // 验证 Widget 交互
    final interactions = yamlToList(createTaskDialogYaml['widget_interactions']);
    expect(interactions.length, equals(2), reason: 'CreateTaskDialog should have 2 interactions');
    
    final formInputInteraction = interactions.firstWhere((i) => i['name'] == 'formInput');
    expect(formInputInteraction['description'], equals('表单输入交互'));
    expect(formInputInteraction['type'], equals('tap'));
    expect(formInputInteraction['handler'], equals('输入处理函数'));
    expect(formInputInteraction['feedback'], equals('视觉反馈'));
    expect(formInputInteraction['accessibility'], equals('支持无障碍'));
    
    final formSubmissionInteraction = interactions.firstWhere((i) => i['name'] == 'formSubmission');
    expect(formSubmissionInteraction['description'], equals('表单提交交互'));
    expect(formSubmissionInteraction['type'], equals('tap'));
    expect(formSubmissionInteraction['handler'], equals('提交处理函数'));
    expect(formSubmissionInteraction['feedback'], equals('视觉反馈'));
    expect(formSubmissionInteraction['accessibility'], equals('支持无障碍'));
    
    // 验证 Widget 动画
    final animations = yamlToList(createTaskDialogYaml['widget_animations']);
    expect(animations.length, equals(1), reason: 'CreateTaskDialog should have 1 animation');
    
    final dialogAnimation = animations.firstWhere((a) => a['name'] == 'dialogAnimation');
    expect(dialogAnimation['description'], equals('对话框动画'));
    expect(dialogAnimation['type'], equals('slide'));
    expect(dialogAnimation['duration'], equals('300ms'));
    expect(dialogAnimation['curve'], equals('easeInOut'));
    expect(dialogAnimation['trigger'], equals('对话框显示'));
    
    // 验证 Widget 验证
    final validation = yamlToList(createTaskDialogYaml['widget_validation']);
    expect(validation.length, equals(3), reason: 'CreateTaskDialog should have 3 validation rules');
    
    final titleValidation = validation.firstWhere((v) => v['field'] == 'title');
    expect(titleValidation['rule'], equals('not_empty'));
    expect(titleValidation['description'], equals('任务标题不能为空'));
    expect(titleValidation['required'], equals(true));
    
    final tagValidation = validation.firstWhere((v) => v['field'] == 'tag');
    expect(tagValidation['rule'], equals('valid_option'));
    expect(tagValidation['description'], equals('标签必须是有效选项'));
    expect(tagValidation['required'], equals(true));
    
    final parentValidation = validation.firstWhere((v) => v['field'] == 'parent');
    expect(parentValidation['rule'], equals('valid_option'));
    expect(parentValidation['description'], equals('父任务必须是有效选项'));
    expect(parentValidation['required'], equals(true));
    
    // 验证 Widget 错误处理
    final errorHandling = yamlToList(createTaskDialogYaml['widget_error_handling']);
    expect(errorHandling.length, equals(2), reason: 'CreateTaskDialog should have 2 error handling');
    
    final validationException = errorHandling.firstWhere((e) => e['exception'] == 'ValidationException');
    expect(validationException['description'], equals('验证异常'));
    expect(validationException['handling'], equals('验证表单并显示错误消息'));
    expect(validationException['recovery'], equals('提供修正建议'));
    expect(validationException['user_feedback'], equals('显示错误消息'));
    
    final submissionException = errorHandling.firstWhere((e) => e['exception'] == 'SubmissionException');
    expect(submissionException['description'], equals('提交异常'));
    expect(submissionException['handling'], equals('处理提交错误并显示错误消息'));
    expect(submissionException['recovery'], equals('重试机制'));
    expect(submissionException['user_feedback'], equals('显示错误消息'));
    
    // 验证 Widget 国际化
    final internationalization = yamlToList(createTaskDialogYaml['widget_internationalization']);
    expect(internationalization.length, equals(1), reason: 'CreateTaskDialog should have 1 internationalization');
    
    final createTaskDialogI18n = internationalization.firstWhere((i) => i['name'] == 'createTaskDialog');
    expect(createTaskDialogI18n['description'], equals('创建任务对话框国际化'));
    expect(createTaskDialogI18n['languages'], equals('zh_CN, en_US'));
    expect(createTaskDialogI18n['fallback'], equals('en_US'));
    expect(createTaskDialogI18n['context'], equals('对话框'));
    
    // 验证 Widget 主题集成
    final themeIntegration = yamlToList(createTaskDialogYaml['widget_theme_integration']);
    expect(themeIntegration.length, equals(2), reason: 'CreateTaskDialog should have 2 theme integrations');
    
    final dialogTheme = themeIntegration.firstWhere((t) => t['name'] == 'dialogTheme');
    expect(dialogTheme['description'], equals('对话框主题'));
    expect(dialogTheme['type'], equals('color'));
    expect(dialogTheme['default_value'], equals('主题色'));
    expect(dialogTheme['theme_aware'], equals(true));
    
    final formTheme = themeIntegration.firstWhere((t) => t['name'] == 'formTheme');
    expect(formTheme['description'], equals('表单主题'));
    expect(formTheme['type'], equals('color'));
    expect(formTheme['default_value'], equals('主题色'));
    expect(formTheme['theme_aware'], equals(true));
    
    // 验证 Widget 状态管理
    final stateManagement = yamlToList(createTaskDialogYaml['widget_state_management']);
    expect(stateManagement.length, equals(1), reason: 'CreateTaskDialog should have 1 state management');
    
    final riverpodStateManagement = stateManagement.firstWhere((s) => s['pattern'] == 'Riverpod 状态管理');
    expect(riverpodStateManagement['description'], equals('使用 Riverpod 管理状态'));
    expect(riverpodStateManagement['implementation'], equals('使用 ConsumerStatefulWidget'));
    expect(riverpodStateManagement['benefits'], equals('响应式、可测试'));
    expect(riverpodStateManagement['considerations'], equals('需要 Provider 配置'));
    
    // 验证 Widget 测试策略
    final testingStrategy = yamlToMap(createTaskDialogYaml['widget_testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull);
    expect(testingStrategy['widget_tests'], isNotNull);
    expect(testingStrategy['integration_tests'], isNotNull);
    expect(testingStrategy['mock_strategy'], isNotNull);
    
    final unitTests = yamlToList(testingStrategy['unit_tests']);
    expect(unitTests.length, equals(10), reason: 'CreateTaskDialog should have 10 unit tests');
    
    final widgetTests = yamlToList(testingStrategy['widget_tests']);
    expect(widgetTests.length, equals(10), reason: 'CreateTaskDialog should have 10 widget tests');
    
    final integrationTests = yamlToList(testingStrategy['integration_tests']);
    expect(integrationTests.length, equals(10), reason: 'CreateTaskDialog should have 10 integration tests');
    
    final mockStrategy = yamlToList(testingStrategy['mock_strategy']);
    expect(mockStrategy.length, equals(3), reason: 'CreateTaskDialog should have 3 mock strategies');
    
    final mockCreateTaskDialog = mockStrategy.firstWhere((m) => m['name'] == 'MockCreateTaskDialog');
    expect(mockCreateTaskDialog['description'], equals('Mock 实现用于测试'));
    
    final fakeCreateTaskDialog = mockStrategy.firstWhere((m) => m['name'] == 'FakeCreateTaskDialog');
    expect(fakeCreateTaskDialog['description'], equals('Fake 实现用于测试'));
    
    final testCreateTaskDialogMock = mockStrategy.firstWhere((m) => m['name'] == 'TestCreateTaskDialog');
    expect(testCreateTaskDialogMock['description'], equals('测试专用 Widget'));
  }

  // 验证 MainDrawer
  static void validateMainDrawer() {
    expect(mainDrawerYaml, isNotNull, reason: 'MainDrawer YAML file should exist');
    
    final widgetDef = yamlToMap(mainDrawerYaml['widget_definition']);
    expect(widgetDef['name'], equals('MainDrawer'));
    expect(widgetDef['layer'], equals('presentation'));
    expect(widgetDef['pattern'], equals('stateless'));
    expect(widgetDef['category'], equals('navigation'));
    expect(widgetDef['reusable'], equals(true));
    
    // 验证 Widget 类型
    final widgetTypes = yamlToList(mainDrawerYaml['widget_types']);
    expect(widgetTypes.length, equals(1), reason: 'MainDrawer should have 1 widget type');
    expect(widgetTypes.any((type) => type['name'] == 'StatelessWidget'), isTrue);
    
    // 验证 Widget 属性
    final properties = yamlToList(mainDrawerYaml['widget_properties']);
    expect(properties.length, equals(1), reason: 'MainDrawer should have 1 property');
    
    final keyProperty = properties.firstWhere((p) => p['name'] == 'key');
    expect(keyProperty['type'], equals('Key?'));
    expect(keyProperty['required'], equals(false));
    
    // 验证 Widget 方法
    final methods = yamlToList(mainDrawerYaml['widget_methods']);
    expect(methods.length, equals(1), reason: 'MainDrawer should have 1 method');
    
    final buildMethod = methods.firstWhere((m) => m['name'] == 'build');
    expect(buildMethod['return_type'], equals('Widget'));
    expect(buildMethod['parameters'].length, equals(1));
    
    // 验证 Widget 状态
    final state = yamlToList(mainDrawerYaml['widget_state']);
    expect(state.length, equals(1), reason: 'MainDrawer should have 1 state');
    
    final destinationsState = state.firstWhere((s) => s['name'] == 'destinations');
    expect(destinationsState['type'], equals('List<SidebarDestination>'));
    expect(destinationsState['initial_value'], equals('SidebarDestinations.values'));
    
    // 验证 Widget 事件
    final events = yamlToList(mainDrawerYaml['widget_events']);
    expect(events.length, equals(1), reason: 'MainDrawer should have 1 event');
    
    final onDestinationSelectedEvent = events.firstWhere((e) => e['name'] == 'onDestinationSelected');
    expect(onDestinationSelectedEvent['description'], equals('导航目标选择事件'));
    expect(onDestinationSelectedEvent['trigger'], equals('用户点击导航项'));
    expect(onDestinationSelectedEvent['handler'], equals('导航处理函数'));
    expect(onDestinationSelectedEvent['parameters'], equals('SidebarDestination destination'));
    
    // 验证 Widget 样式
    final styling = yamlToList(mainDrawerYaml['widget_styling']);
    expect(styling.length, equals(2), reason: 'MainDrawer should have 2 styling');
    
    final drawerStyle = styling.firstWhere((s) => s['name'] == 'drawerStyle');
    expect(drawerStyle['description'], equals('抽屉样式'));
    expect(drawerStyle['responsive'], equals(false));
    expect(drawerStyle['theme_aware'], equals(true));
    
    final headerStyle = styling.firstWhere((s) => s['name'] == 'headerStyle');
    expect(headerStyle['description'], equals('头部样式'));
    expect(headerStyle['responsive'], equals(false));
    expect(headerStyle['theme_aware'], equals(true));
    
    // 验证 Widget 响应式
    final responsive = yamlToList(mainDrawerYaml['widget_responsive']);
    expect(responsive.length, equals(3), reason: 'MainDrawer should have 3 responsive breakpoints');
    
    final mobileResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'mobile');
    expect(mobileResponsive['description'], equals('移动端响应式'));
    expect(mobileResponsive['layout'], equals('Drawer 布局'));
    expect(mobileResponsive['behavior'], equals('侧滑显示'));
    
    final tabletResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'tablet');
    expect(tabletResponsive['description'], equals('平板端响应式'));
    expect(tabletResponsive['layout'], equals('Drawer 布局'));
    expect(tabletResponsive['behavior'], equals('侧滑显示'));
    
    final desktopResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'desktop');
    expect(desktopResponsive['description'], equals('桌面端响应式'));
    expect(desktopResponsive['layout'], equals('Drawer 布局'));
    expect(desktopResponsive['behavior'], equals('侧滑显示'));
    
    // 验证 Widget 无障碍
    final accessibility = yamlToList(mainDrawerYaml['widget_accessibility']);
    expect(accessibility.length, equals(2), reason: 'MainDrawer should have 2 accessibility features');
    
    final semanticLabel = accessibility.firstWhere((a) => a['name'] == 'semanticLabel');
    expect(semanticLabel['description'], equals('语义标签'));
    expect(semanticLabel['compliance'], equals('WCAG 2.1'));
    
    final keyboardNavigation = accessibility.firstWhere((a) => a['name'] == 'keyboardNavigation');
    expect(keyboardNavigation['description'], equals('键盘导航'));
    expect(keyboardNavigation['compliance'], equals('WCAG 2.1'));
    
    // 验证 Widget 性能
    final performance = yamlToList(mainDrawerYaml['widget_performance']);
    expect(performance.length, equals(2), reason: 'MainDrawer should have 2 performance considerations');
    
    final buildPerformance = performance.firstWhere((p) => p['operation'] == 'build');
    expect(buildPerformance['optimization'], equals('构建优化'));
    expect(buildPerformance['description'], equals('构建性能优化'));
    
    final navigationPerformance = performance.firstWhere((p) => p['operation'] == 'navigation');
    expect(navigationPerformance['optimization'], equals('导航优化'));
    expect(navigationPerformance['description'], equals('导航性能优化'));
    
    // 验证 Widget 测试
    final testing = yamlToList(mainDrawerYaml['widget_testing']);
    expect(testing.length, equals(1), reason: 'MainDrawer should have 1 testing strategy');
    
    final testMainDrawer = testing.firstWhere((t) => t['name'] == 'testMainDrawer');
    expect(testMainDrawer['description'], equals('测试主抽屉'));
    expect(testMainDrawer['type'], equals('widget'));
    expect(testMainDrawer['coverage'], equals('100%'));
    expect(testMainDrawer['scenarios'], equals('导航、样式、响应式、无障碍'));
    
    // 验证 Widget 依赖
    final dependencies = yamlToList(mainDrawerYaml['widget_dependencies']);
    expect(dependencies.length, equals(1), reason: 'MainDrawer should have 1 dependency');
    
    final sidebarDestinationsDependency = dependencies.firstWhere((d) => d['name'] == 'SidebarDestinations');
    expect(sidebarDestinationsDependency['type'], equals('导航目标'));
    expect(sidebarDestinationsDependency['description'], equals('侧边栏导航目标'));
    expect(sidebarDestinationsDependency['required'], equals(true));
    
    // 验证 Widget 导入
    final imports = yamlToList(mainDrawerYaml['widget_imports']);
    expect(imports.length, equals(3), reason: 'MainDrawer should have 3 imports');
    expect(imports, contains('package:flutter/material.dart'));
    expect(imports, contains('package:go_router/go_router.dart'));
    expect(imports, contains('../navigation/sidebar_destinations.dart'));
    
    // 验证 Widget 分类
    final categories = yamlToMap(mainDrawerYaml['widget_categories']);
    expect(categories['navigation'], isNotNull);
    
    final navigation = yamlToList(categories['navigation']);
    expect(navigation.length, equals(1), reason: 'MainDrawer should have 1 navigation');
    
    final mainDrawerComponent = navigation.firstWhere((c) => c['name'] == 'MainDrawer');
    expect(mainDrawerComponent['description'], equals('主抽屉组件'));
    expect(mainDrawerComponent['type'], equals('StatelessWidget'));
    expect(mainDrawerComponent['category'], equals('navigation'));
    
    // 验证 Widget 交互
    final interactions = yamlToList(mainDrawerYaml['widget_interactions']);
    expect(interactions.length, equals(3), reason: 'MainDrawer should have 3 interactions');
    
    final drawerOpenInteraction = interactions.firstWhere((i) => i['name'] == 'drawerOpen');
    expect(drawerOpenInteraction['description'], equals('抽屉打开交互'));
    expect(drawerOpenInteraction['type'], equals('swipe'));
    expect(drawerOpenInteraction['handler'], equals('打开处理函数'));
    expect(drawerOpenInteraction['feedback'], equals('视觉反馈'));
    expect(drawerOpenInteraction['accessibility'], equals('支持无障碍'));
    
    final drawerCloseInteraction = interactions.firstWhere((i) => i['name'] == 'drawerClose');
    expect(drawerCloseInteraction['description'], equals('抽屉关闭交互'));
    expect(drawerCloseInteraction['type'], equals('swipe'));
    expect(drawerCloseInteraction['handler'], equals('关闭处理函数'));
    expect(drawerCloseInteraction['feedback'], equals('视觉反馈'));
    expect(drawerCloseInteraction['accessibility'], equals('支持无障碍'));
    
    final navigationItemTapInteraction = interactions.firstWhere((i) => i['name'] == 'navigationItemTap');
    expect(navigationItemTapInteraction['description'], equals('导航项点击交互'));
    expect(navigationItemTapInteraction['type'], equals('tap'));
    expect(navigationItemTapInteraction['handler'], equals('导航处理函数'));
    expect(navigationItemTapInteraction['feedback'], equals('视觉反馈'));
    expect(navigationItemTapInteraction['accessibility'], equals('支持无障碍'));
    
    // 验证 Widget 动画
    final animations = yamlToList(mainDrawerYaml['widget_animations']);
    expect(animations.length, equals(1), reason: 'MainDrawer should have 1 animation');
    
    final drawerAnimation = animations.firstWhere((a) => a['name'] == 'drawerAnimation');
    expect(drawerAnimation['description'], equals('抽屉动画'));
    expect(drawerAnimation['type'], equals('slide'));
    expect(drawerAnimation['duration'], equals('300ms'));
    expect(drawerAnimation['curve'], equals('easeInOut'));
    expect(drawerAnimation['trigger'], equals('抽屉显示'));
    
    // 验证 Widget 验证
    final validation = yamlToList(mainDrawerYaml['widget_validation']);
    expect(validation.length, equals(1), reason: 'MainDrawer should have 1 validation rule');
    
    final destinationsValidation = validation.firstWhere((v) => v['field'] == 'destinations');
    expect(destinationsValidation['rule'], equals('not_empty'));
    expect(destinationsValidation['description'], equals('导航目标不能为空'));
    expect(destinationsValidation['required'], equals(true));
    
    // 验证 Widget 错误处理
    final errorHandling = yamlToList(mainDrawerYaml['widget_error_handling']);
    expect(errorHandling.length, equals(1), reason: 'MainDrawer should have 1 error handling');
    
    final navigationException = errorHandling.firstWhere((e) => e['exception'] == 'NavigationException');
    expect(navigationException['description'], equals('导航异常'));
    expect(navigationException['handling'], equals('处理导航错误并显示错误消息'));
    expect(navigationException['recovery'], equals('重试机制'));
    expect(navigationException['user_feedback'], equals('显示错误消息'));
    
    // 验证 Widget 国际化
    final internationalization = yamlToList(mainDrawerYaml['widget_internationalization']);
    expect(internationalization.length, equals(1), reason: 'MainDrawer should have 1 internationalization');
    
    final mainDrawerI18n = internationalization.firstWhere((i) => i['name'] == 'mainDrawer');
    expect(mainDrawerI18n['description'], equals('主抽屉国际化'));
    expect(mainDrawerI18n['languages'], equals('zh_CN, en_US'));
    expect(mainDrawerI18n['fallback'], equals('en_US'));
    expect(mainDrawerI18n['context'], equals('导航组件'));
    
    // 验证 Widget 主题集成
    final themeIntegration = yamlToList(mainDrawerYaml['widget_theme_integration']);
    expect(themeIntegration.length, equals(2), reason: 'MainDrawer should have 2 theme integrations');
    
    final drawerTheme = themeIntegration.firstWhere((t) => t['name'] == 'drawerTheme');
    expect(drawerTheme['description'], equals('抽屉主题'));
    expect(drawerTheme['type'], equals('color'));
    expect(drawerTheme['default_value'], equals('主题色'));
    expect(drawerTheme['theme_aware'], equals(true));
    
    final headerTheme = themeIntegration.firstWhere((t) => t['name'] == 'headerTheme');
    expect(headerTheme['description'], equals('头部主题'));
    expect(headerTheme['type'], equals('color'));
    expect(headerTheme['default_value'], equals('主题色'));
    expect(headerTheme['theme_aware'], equals(true));
    
    // 验证 Widget 状态管理
    final stateManagement = yamlToList(mainDrawerYaml['widget_state_management']);
    expect(stateManagement.length, equals(1), reason: 'MainDrawer should have 1 state management');
    
    final externalStateManagement = stateManagement.firstWhere((s) => s['pattern'] == '外部状态管理');
    expect(externalStateManagement['description'], equals('通过回调管理状态'));
    expect(externalStateManagement['implementation'], equals('使用导航回调'));
    expect(externalStateManagement['benefits'], equals('解耦、可复用'));
    expect(externalStateManagement['considerations'], equals('需要外部状态管理'));
    
    // 验证 Widget 测试策略
    final testingStrategy = yamlToMap(mainDrawerYaml['widget_testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull);
    expect(testingStrategy['widget_tests'], isNotNull);
    expect(testingStrategy['integration_tests'], isNotNull);
    expect(testingStrategy['mock_strategy'], isNotNull);
    
    final unitTests = yamlToList(testingStrategy['unit_tests']);
    expect(unitTests.length, equals(10), reason: 'MainDrawer should have 10 unit tests');
    
    final widgetTests = yamlToList(testingStrategy['widget_tests']);
    expect(widgetTests.length, equals(10), reason: 'MainDrawer should have 10 widget tests');
    
    final integrationTests = yamlToList(testingStrategy['integration_tests']);
    expect(integrationTests.length, equals(10), reason: 'MainDrawer should have 10 integration tests');
    
    final mockStrategy = yamlToList(testingStrategy['mock_strategy']);
    expect(mockStrategy.length, equals(3), reason: 'MainDrawer should have 3 mock strategies');
    
    final mockMainDrawer = mockStrategy.firstWhere((m) => m['name'] == 'MockMainDrawer');
    expect(mockMainDrawer['description'], equals('Mock 实现用于测试'));
    
    final fakeMainDrawer = mockStrategy.firstWhere((m) => m['name'] == 'FakeMainDrawer');
    expect(fakeMainDrawer['description'], equals('Fake 实现用于测试'));
    
    final testMainDrawerMock = mockStrategy.firstWhere((m) => m['name'] == 'TestMainDrawer');
    expect(testMainDrawerMock['description'], equals('测试专用 Widget'));
  }

  // 验证 PageAppBar
  static void validatePageAppBar() {
    expect(pageAppBarYaml, isNotNull, reason: 'PageAppBar YAML file should exist');
    
    final widgetDef = yamlToMap(pageAppBarYaml['widget_definition']);
    expect(widgetDef['name'], equals('PageAppBar'));
    expect(widgetDef['layer'], equals('presentation'));
    expect(widgetDef['pattern'], equals('stateless'));
    expect(widgetDef['category'], equals('navigation'));
    expect(widgetDef['reusable'], equals(true));
    
    // 验证 Widget 类型
    final widgetTypes = yamlToList(pageAppBarYaml['widget_types']);
    expect(widgetTypes.length, equals(2), reason: 'PageAppBar should have 2 widget types');
    expect(widgetTypes.any((type) => type['name'] == 'StatelessWidget'), isTrue);
    expect(widgetTypes.any((type) => type['name'] == 'PreferredSizeWidget'), isTrue);
    
    // 验证 Widget 属性
    final properties = yamlToList(pageAppBarYaml['widget_properties']);
    expect(properties.length, equals(4), reason: 'PageAppBar should have 4 properties');
    
    final titleProperty = properties.firstWhere((p) => p['name'] == 'title');
    expect(titleProperty['type'], equals('String'));
    expect(titleProperty['required'], equals(true));
    
    final actionsProperty = properties.firstWhere((p) => p['name'] == 'actions');
    expect(actionsProperty['type'], equals('List<Widget>?'));
    expect(actionsProperty['required'], equals(false));
    
    final showMenuButtonProperty = properties.firstWhere((p) => p['name'] == 'showMenuButton');
    expect(showMenuButtonProperty['type'], equals('bool'));
    expect(showMenuButtonProperty['required'], equals(false));
    expect(showMenuButtonProperty['default_value'], equals('true'));
    
    final automaticallyImplyLeadingProperty = properties.firstWhere((p) => p['name'] == 'automaticallyImplyLeading');
    expect(automaticallyImplyLeadingProperty['type'], equals('bool'));
    expect(automaticallyImplyLeadingProperty['required'], equals(false));
    expect(automaticallyImplyLeadingProperty['default_value'], equals('false'));
    
    // 验证 Widget 方法
    final methods = yamlToList(pageAppBarYaml['widget_methods']);
    expect(methods.length, equals(3), reason: 'PageAppBar should have 3 methods');
    
    final buildMethod = methods.firstWhere((m) => m['name'] == 'build');
    expect(buildMethod['return_type'], equals('Widget'));
    expect(buildMethod['parameters'].length, equals(1));
    
    final preferredSizeMethod = methods.firstWhere((m) => m['name'] == 'preferredSize');
    expect(preferredSizeMethod['return_type'], equals('Size'));
    expect(preferredSizeMethod['parameters'].length, equals(0));
    
    final buildLeadingMethod = methods.firstWhere((m) => m['name'] == '_buildLeading');
    expect(buildLeadingMethod['return_type'], equals('Widget?'));
    expect(buildLeadingMethod['parameters'].length, equals(1));
    expect(buildLeadingMethod['visibility'], equals('private'));
    
    // 验证 Widget 状态
    final state = yamlToList(pageAppBarYaml['widget_state']);
    expect(state.length, equals(3), reason: 'PageAppBar should have 3 states');
    
    final titleState = state.firstWhere((s) => s['name'] == 'title');
    expect(titleState['type'], equals('String'));
    expect(titleState['initial_value'], equals('空字符串'));
    
    final showMenuButtonState = state.firstWhere((s) => s['name'] == 'showMenuButton');
    expect(showMenuButtonState['type'], equals('bool'));
    expect(showMenuButtonState['initial_value'], equals('true'));
    
    final automaticallyImplyLeadingState = state.firstWhere((s) => s['name'] == 'automaticallyImplyLeading');
    expect(automaticallyImplyLeadingState['type'], equals('bool'));
    expect(automaticallyImplyLeadingState['initial_value'], equals('false'));
    
    // 验证 Widget 事件
    final events = yamlToList(pageAppBarYaml['widget_events']);
    expect(events.length, equals(2), reason: 'PageAppBar should have 2 events');
    
    final onMenuPressedEvent = events.firstWhere((e) => e['name'] == 'onMenuPressed');
    expect(onMenuPressedEvent['description'], equals('主菜单按钮点击事件'));
    expect(onMenuPressedEvent['trigger'], equals('用户点击主菜单按钮'));
    expect(onMenuPressedEvent['handler'], equals('打开抽屉处理函数'));
    expect(onMenuPressedEvent['parameters'], equals('无'));
    
    final onActionPressedEvent = events.firstWhere((e) => e['name'] == 'onActionPressed');
    expect(onActionPressedEvent['description'], equals('操作按钮点击事件'));
    expect(onActionPressedEvent['trigger'], equals('用户点击操作按钮'));
    expect(onActionPressedEvent['handler'], equals('操作处理函数'));
    expect(onActionPressedEvent['parameters'], equals('操作类型'));
    
    // 验证 Widget 样式
    final styling = yamlToList(pageAppBarYaml['widget_styling']);
    expect(styling.length, equals(2), reason: 'PageAppBar should have 2 styling');
    
    final appBarStyle = styling.firstWhere((s) => s['name'] == 'appBarStyle');
    expect(appBarStyle['description'], equals('导航栏样式'));
    expect(appBarStyle['responsive'], equals(false));
    expect(appBarStyle['theme_aware'], equals(true));
    
    final titleStyle = styling.firstWhere((s) => s['name'] == 'titleStyle');
    expect(titleStyle['description'], equals('标题样式'));
    expect(titleStyle['responsive'], equals(false));
    expect(titleStyle['theme_aware'], equals(true));
    
    // 验证 Widget 响应式
    final responsive = yamlToList(pageAppBarYaml['widget_responsive']);
    expect(responsive.length, equals(3), reason: 'PageAppBar should have 3 responsive breakpoints');
    
    final mobileResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'mobile');
    expect(mobileResponsive['description'], equals('移动端响应式'));
    expect(mobileResponsive['layout'], equals('AppBar 布局'));
    expect(mobileResponsive['behavior'], equals('标准导航栏'));
    
    final tabletResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'tablet');
    expect(tabletResponsive['description'], equals('平板端响应式'));
    expect(tabletResponsive['layout'], equals('AppBar 布局'));
    expect(tabletResponsive['behavior'], equals('标准导航栏'));
    
    final desktopResponsive = responsive.firstWhere((r) => r['breakpoint'] == 'desktop');
    expect(desktopResponsive['description'], equals('桌面端响应式'));
    expect(desktopResponsive['layout'], equals('AppBar 布局'));
    expect(desktopResponsive['behavior'], equals('标准导航栏'));
    
    // 验证 Widget 无障碍
    final accessibility = yamlToList(pageAppBarYaml['widget_accessibility']);
    expect(accessibility.length, equals(2), reason: 'PageAppBar should have 2 accessibility features');
    
    final semanticLabel = accessibility.firstWhere((a) => a['name'] == 'semanticLabel');
    expect(semanticLabel['description'], equals('语义标签'));
    expect(semanticLabel['compliance'], equals('WCAG 2.1'));
    
    final keyboardNavigation = accessibility.firstWhere((a) => a['name'] == 'keyboardNavigation');
    expect(keyboardNavigation['description'], equals('键盘导航'));
    expect(keyboardNavigation['compliance'], equals('WCAG 2.1'));
    
    // 验证 Widget 性能
    final performance = yamlToList(pageAppBarYaml['widget_performance']);
    expect(performance.length, equals(2), reason: 'PageAppBar should have 2 performance considerations');
    
    final buildPerformance = performance.firstWhere((p) => p['operation'] == 'build');
    expect(buildPerformance['optimization'], equals('构建优化'));
    expect(buildPerformance['description'], equals('构建性能优化'));
    
    final navigationPerformance = performance.firstWhere((p) => p['operation'] == 'navigation');
    expect(navigationPerformance['optimization'], equals('导航优化'));
    expect(navigationPerformance['description'], equals('导航性能优化'));
    
    // 验证 Widget 测试
    final testing = yamlToList(pageAppBarYaml['widget_testing']);
    expect(testing.length, equals(1), reason: 'PageAppBar should have 1 testing strategy');
    
    final testPageAppBar = testing.firstWhere((t) => t['name'] == 'testPageAppBar');
    expect(testPageAppBar['description'], equals('测试页面导航栏'));
    expect(testPageAppBar['type'], equals('widget'));
    expect(testPageAppBar['coverage'], equals('100%'));
    expect(testPageAppBar['scenarios'], equals('标题、按钮、样式、响应式、无障碍'));
    
    // 验证 Widget 依赖
    final dependencies = yamlToList(pageAppBarYaml['widget_dependencies']);
    expect(dependencies.length, equals(1), reason: 'PageAppBar should have 1 dependency');
    
    final flutterMaterialDependency = dependencies.firstWhere((d) => d['name'] == 'Flutter Material');
    expect(flutterMaterialDependency['type'], equals('UI 框架'));
    expect(flutterMaterialDependency['description'], equals('Flutter Material 设计'));
    expect(flutterMaterialDependency['required'], equals(true));
    
    // 验证 Widget 导入
    final imports = yamlToList(pageAppBarYaml['widget_imports']);
    expect(imports.length, equals(1), reason: 'PageAppBar should have 1 import');
    expect(imports, contains('package:flutter/material.dart'));
    
    // 验证 Widget 分类
    final categories = yamlToMap(pageAppBarYaml['widget_categories']);
    expect(categories['navigation'], isNotNull);
    
    final navigation = yamlToList(categories['navigation']);
    expect(navigation.length, equals(1), reason: 'PageAppBar should have 1 navigation');
    
    final pageAppBarComponent = navigation.firstWhere((c) => c['name'] == 'PageAppBar');
    expect(pageAppBarComponent['description'], equals('页面导航栏组件'));
    expect(pageAppBarComponent['type'], equals('StatelessWidget'));
    expect(pageAppBarComponent['category'], equals('navigation'));
    
    // 验证 Widget 交互
    final interactions = yamlToList(pageAppBarYaml['widget_interactions']);
    expect(interactions.length, equals(2), reason: 'PageAppBar should have 2 interactions');
    
    final menuButtonTapInteraction = interactions.firstWhere((i) => i['name'] == 'menuButtonTap');
    expect(menuButtonTapInteraction['description'], equals('主菜单按钮点击交互'));
    expect(menuButtonTapInteraction['type'], equals('tap'));
    expect(menuButtonTapInteraction['handler'], equals('打开抽屉处理函数'));
    expect(menuButtonTapInteraction['feedback'], equals('视觉反馈'));
    expect(menuButtonTapInteraction['accessibility'], equals('支持无障碍'));
    
    final actionButtonTapInteraction = interactions.firstWhere((i) => i['name'] == 'actionButtonTap');
    expect(actionButtonTapInteraction['description'], equals('操作按钮点击交互'));
    expect(actionButtonTapInteraction['type'], equals('tap'));
    expect(actionButtonTapInteraction['handler'], equals('操作处理函数'));
    expect(actionButtonTapInteraction['feedback'], equals('视觉反馈'));
    expect(actionButtonTapInteraction['accessibility'], equals('支持无障碍'));
    
    // 验证 Widget 动画
    final animations = yamlToList(pageAppBarYaml['widget_animations']);
    expect(animations.length, equals(1), reason: 'PageAppBar should have 1 animation');
    
    final appBarAnimation = animations.firstWhere((a) => a['name'] == 'appBarAnimation');
    expect(appBarAnimation['description'], equals('导航栏动画'));
    expect(appBarAnimation['type'], equals('fade'));
    expect(appBarAnimation['duration'], equals('200ms'));
    expect(appBarAnimation['curve'], equals('easeInOut'));
    expect(appBarAnimation['trigger'], equals('导航栏显示'));
    
    // 验证 Widget 验证
    final validation = yamlToList(pageAppBarYaml['widget_validation']);
    expect(validation.length, equals(1), reason: 'PageAppBar should have 1 validation rule');
    
    final titleValidation = validation.firstWhere((v) => v['field'] == 'title');
    expect(titleValidation['rule'], equals('not_empty'));
    expect(titleValidation['description'], equals('标题不能为空'));
    expect(titleValidation['required'], equals(true));
    
    // 验证 Widget 错误处理
    final errorHandling = yamlToList(pageAppBarYaml['widget_error_handling']);
    expect(errorHandling.length, equals(1), reason: 'PageAppBar should have 1 error handling');
    
    final navigationException = errorHandling.firstWhere((e) => e['exception'] == 'NavigationException');
    expect(navigationException['description'], equals('导航异常'));
    expect(navigationException['handling'], equals('处理导航错误并显示错误消息'));
    expect(navigationException['recovery'], equals('重试机制'));
    expect(navigationException['user_feedback'], equals('显示错误消息'));
    
    // 验证 Widget 国际化
    final internationalization = yamlToList(pageAppBarYaml['widget_internationalization']);
    expect(internationalization.length, equals(1), reason: 'PageAppBar should have 1 internationalization');
    
    final pageAppBarI18n = internationalization.firstWhere((i) => i['name'] == 'pageAppBar');
    expect(pageAppBarI18n['description'], equals('页面导航栏国际化'));
    expect(pageAppBarI18n['languages'], equals('zh_CN, en_US'));
    expect(pageAppBarI18n['fallback'], equals('en_US'));
    expect(pageAppBarI18n['context'], equals('导航组件'));
    
    // 验证 Widget 主题集成
    final themeIntegration = yamlToList(pageAppBarYaml['widget_theme_integration']);
    expect(themeIntegration.length, equals(2), reason: 'PageAppBar should have 2 theme integrations');
    
    final appBarTheme = themeIntegration.firstWhere((t) => t['name'] == 'appBarTheme');
    expect(appBarTheme['description'], equals('导航栏主题'));
    expect(appBarTheme['type'], equals('color'));
    expect(appBarTheme['default_value'], equals('主题色'));
    expect(appBarTheme['theme_aware'], equals(true));
    
    final titleTheme = themeIntegration.firstWhere((t) => t['name'] == 'titleTheme');
    expect(titleTheme['description'], equals('标题主题'));
    expect(titleTheme['type'], equals('text_style'));
    expect(titleTheme['default_value'], equals('主题文字样式'));
    expect(titleTheme['theme_aware'], equals(true));
    
    // 验证 Widget 状态管理
    final stateManagement = yamlToList(pageAppBarYaml['widget_state_management']);
    expect(stateManagement.length, equals(1), reason: 'PageAppBar should have 1 state management');
    
    final externalStateManagement = stateManagement.firstWhere((s) => s['pattern'] == '外部状态管理');
    expect(externalStateManagement['description'], equals('通过回调管理状态'));
    expect(externalStateManagement['implementation'], equals('使用导航回调'));
    expect(externalStateManagement['benefits'], equals('解耦、可复用'));
    expect(externalStateManagement['considerations'], equals('需要外部状态管理'));
    
    // 验证 Widget 测试策略
    final testingStrategy = yamlToMap(pageAppBarYaml['widget_testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull);
    expect(testingStrategy['widget_tests'], isNotNull);
    expect(testingStrategy['integration_tests'], isNotNull);
    expect(testingStrategy['mock_strategy'], isNotNull);
    
    final unitTests = yamlToList(testingStrategy['unit_tests']);
    expect(unitTests.length, equals(10), reason: 'PageAppBar should have 10 unit tests');
    
    final widgetTests = yamlToList(testingStrategy['widget_tests']);
    expect(widgetTests.length, equals(10), reason: 'PageAppBar should have 10 widget tests');
    
    final integrationTests = yamlToList(testingStrategy['integration_tests']);
    expect(integrationTests.length, equals(10), reason: 'PageAppBar should have 10 integration tests');
    
    final mockStrategy = yamlToList(testingStrategy['mock_strategy']);
    expect(mockStrategy.length, equals(3), reason: 'PageAppBar should have 3 mock strategies');
    
    final mockPageAppBar = mockStrategy.firstWhere((m) => m['name'] == 'MockPageAppBar');
    expect(mockPageAppBar['description'], equals('Mock 实现用于测试'));
    
    final fakePageAppBar = mockStrategy.firstWhere((m) => m['name'] == 'FakePageAppBar');
    expect(fakePageAppBar['description'], equals('Fake 实现用于测试'));
    
    final testPageAppBarMock = mockStrategy.firstWhere((m) => m['name'] == 'TestPageAppBar');
    expect(testPageAppBarMock['description'], equals('测试专用 Widget'));
  }

  // 验证所有 Widget 的一致性
  static void validateAllWidgetsConsistency() {
    // 验证所有 Widget 都有正确的元数据
    final allYamls = [chipToggleGroupYaml, createTaskDialogYaml, mainDrawerYaml, pageAppBarYaml];
    
    for (final yaml in allYamls) {
      expect(yaml['meta'], isNotNull, reason: 'All widgets should have meta section');
      expect(yaml['meta']['name'], isNotNull, reason: 'All widgets should have name');
      expect(yaml['meta']['type'], equals('widget'), reason: 'All widgets should have type widget');
      expect(yaml['meta']['file_path'], isNotNull, reason: 'All widgets should have file_path');
      expect(yaml['meta']['description'], isNotNull, reason: 'All widgets should have description');
      
      expect(yaml['widget_definition'], isNotNull, reason: 'All widgets should have widget_definition');
      expect(yaml['widget_definition']['name'], isNotNull, reason: 'All widgets should have widget name');
      expect(yaml['widget_definition']['layer'], equals('presentation'), reason: 'All widgets should have layer presentation');
      expect(yaml['widget_definition']['pattern'], isNotNull, reason: 'All widgets should have pattern');
      expect(yaml['widget_definition']['category'], isNotNull, reason: 'All widgets should have category');
      expect(yaml['widget_definition']['reusable'], isNotNull, reason: 'All widgets should have reusable');
      
      expect(yaml['widget_types'], isNotNull, reason: 'All widgets should have widget_types');
      expect(yaml['widget_types'], isA<List>(), reason: 'All widgets should have widget_types as list');
      expect((yaml['widget_types'] as List).isNotEmpty, isTrue, reason: 'All widgets should have non-empty widget_types');
      
      expect(yaml['widget_properties'], isNotNull, reason: 'All widgets should have widget_properties');
      expect(yaml['widget_properties'], isA<List>(), reason: 'All widgets should have widget_properties as list');
      
      expect(yaml['widget_methods'], isNotNull, reason: 'All widgets should have widget_methods');
      expect(yaml['widget_methods'], isA<List>(), reason: 'All widgets should have widget_methods as list');
      
      expect(yaml['widget_state'], isNotNull, reason: 'All widgets should have widget_state');
      expect(yaml['widget_state'], isA<List>(), reason: 'All widgets should have widget_state as list');
      
      expect(yaml['widget_lifecycle'], isNotNull, reason: 'All widgets should have widget_lifecycle');
      expect(yaml['widget_lifecycle'], isA<List>(), reason: 'All widgets should have widget_lifecycle as list');
      
      expect(yaml['widget_events'], isNotNull, reason: 'All widgets should have widget_events');
      expect(yaml['widget_events'], isA<List>(), reason: 'All widgets should have widget_events as list');
      
      expect(yaml['widget_styling'], isNotNull, reason: 'All widgets should have widget_styling');
      expect(yaml['widget_styling'], isA<List>(), reason: 'All widgets should have widget_styling as list');
      
      expect(yaml['widget_responsive'], isNotNull, reason: 'All widgets should have widget_responsive');
      expect(yaml['widget_responsive'], isA<List>(), reason: 'All widgets should have widget_responsive as list');
      
      expect(yaml['widget_accessibility'], isNotNull, reason: 'All widgets should have widget_accessibility');
      expect(yaml['widget_accessibility'], isA<List>(), reason: 'All widgets should have widget_accessibility as list');
      
      expect(yaml['widget_performance'], isNotNull, reason: 'All widgets should have widget_performance');
      expect(yaml['widget_performance'], isA<List>(), reason: 'All widgets should have widget_performance as list');
      
      expect(yaml['widget_testing'], isNotNull, reason: 'All widgets should have widget_testing');
      expect(yaml['widget_testing'], isA<List>(), reason: 'All widgets should have widget_testing as list');
      
      expect(yaml['widget_dependencies'], isNotNull, reason: 'All widgets should have widget_dependencies');
      expect(yaml['widget_dependencies'], isA<List>(), reason: 'All widgets should have widget_dependencies as list');
      
      expect(yaml['widget_imports'], isNotNull, reason: 'All widgets should have widget_imports');
      expect(yaml['widget_imports'], isA<List>(), reason: 'All widgets should have widget_imports as list');
      
      expect(yaml['widget_categories'], isNotNull, reason: 'All widgets should have widget_categories');
      expect(yaml['widget_categories'], isA<Map>(), reason: 'All widgets should have widget_categories as map');
      
      expect(yaml['widget_interactions'], isNotNull, reason: 'All widgets should have widget_interactions');
      expect(yaml['widget_interactions'], isA<List>(), reason: 'All widgets should have widget_interactions as list');
      
      expect(yaml['widget_animations'], isNotNull, reason: 'All widgets should have widget_animations');
      expect(yaml['widget_animations'], isA<List>(), reason: 'All widgets should have widget_animations as list');
      
      expect(yaml['widget_validation'], isNotNull, reason: 'All widgets should have widget_validation');
      expect(yaml['widget_validation'], isA<List>(), reason: 'All widgets should have widget_validation as list');
      
      expect(yaml['widget_error_handling'], isNotNull, reason: 'All widgets should have widget_error_handling');
      expect(yaml['widget_error_handling'], isA<List>(), reason: 'All widgets should have widget_error_handling as list');
      
      expect(yaml['widget_internationalization'], isNotNull, reason: 'All widgets should have widget_internationalization');
      expect(yaml['widget_internationalization'], isA<List>(), reason: 'All widgets should have widget_internationalization as list');
      
      expect(yaml['widget_theme_integration'], isNotNull, reason: 'All widgets should have widget_theme_integration');
      expect(yaml['widget_theme_integration'], isA<List>(), reason: 'All widgets should have widget_theme_integration as list');
      
      expect(yaml['widget_state_management'], isNotNull, reason: 'All widgets should have widget_state_management');
      expect(yaml['widget_state_management'], isA<List>(), reason: 'All widgets should have widget_state_management as list');
      
      expect(yaml['widget_testing_strategy'], isNotNull, reason: 'All widgets should have widget_testing_strategy');
      expect(yaml['widget_testing_strategy'], isA<Map>(), reason: 'All widgets should have widget_testing_strategy as map');
    }
  }
}

void main() {
  group('Widgets YAML Tests', () {
    setUpAll(() async {
      await WidgetsYAMLTest.loadYAMLFiles();
    });

    test('ChipToggleGroup should match YAML definition', () {
      WidgetsYAMLTest.validateChipToggleGroup();
    });

    test('CreateTaskDialog should match YAML definition', () {
      WidgetsYAMLTest.validateCreateTaskDialog();
    });

    test('MainDrawer should match YAML definition', () {
      WidgetsYAMLTest.validateMainDrawer();
    });

    test('PageAppBar should match YAML definition', () {
      WidgetsYAMLTest.validatePageAppBar();
    });

    test('All widgets should have consistent structure', () {
      WidgetsYAMLTest.validateAllWidgetsConsistency();
    });
  });
}
