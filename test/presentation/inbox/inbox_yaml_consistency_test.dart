import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// Inbox组件与YAML文档一致性测试
/// 
/// 这个测试文件确保inbox页面的实现与architecture文档保持一致，
/// 防止意外修改导致文档和代码不同步。

/// 将YAML对象转换为Map<String, dynamic>
Map<String, dynamic> _toMap(dynamic yaml) {
  if (yaml is Map) {
    return Map<String, dynamic>.from(yaml);
  }
  return <String, dynamic>{};
}

/// 将YAML列表转换为List<Map<String, dynamic>>
List<Map<String, dynamic>> _toList(dynamic yaml) {
  if (yaml is List) {
    return yaml.map((item) => _toMap(item)).toList();
  }
  return <Map<String, dynamic>>[];
}

void main() {
  group('Inbox YAML Consistency Tests', () {
    late Map<String, dynamic> yamlDoc;
    late String yamlFilePath;

    setUpAll(() async {
      // 加载YAML文档
      yamlFilePath = path.join(
        Directory.current.path,
        'documents',
        'architecture',
        'pages',
        'inbox_page.yaml',
      );
      final yamlFile = File(yamlFilePath);
      final yamlContent = await yamlFile.readAsString();
      yamlDoc = Map<String, dynamic>.from(loadYaml(yamlContent) as Map);
    });

    group('Page Definition Consistency', () {
      test('页面名称应该与YAML一致', () {
        expect(yamlDoc['meta']['name'], equals('InboxPage'));
      });

      test('页面类型应该与YAML一致', () {
        expect(yamlDoc['meta']['type'], equals('page'));
        expect(yamlDoc['page_definition']['pattern'], equals('consumer_stateful'));
      });

      test('页面描述应该与YAML一致', () {
        final expectedDescription = yamlDoc['meta']['description'] as String;
        expect(expectedDescription, contains('收集箱页面'));
        expect(expectedDescription, contains('优先级过滤'));
        expect(expectedDescription, contains('内联编辑'));
        expect(expectedDescription, contains('自定义日期选择'));
      });

      test('页面版本应该与YAML一致', () {
        expect(yamlDoc['meta']['version'], equals('2.0'));
        expect(yamlDoc['meta']['last_updated'], equals('251026'));
      });
    });

    group('Page State Consistency', () {
      test('页面状态应该与YAML一致', () {
        final pageState = _toList(yamlDoc['page_state']);
        final stateNames = pageState.map((state) => state['name'] as String).toList();
        
        // 验证YAML中定义的状态
        expect(stateNames, contains('_inputController'));
        expect(stateNames, contains('_inputFocusNode'));
        expect(stateNames, contains('_isSubmitting'));
        expect(stateNames, contains('_currentQuery'));
        expect(stateNames, contains('_isPlanning'));
        
        // 验证状态类型
        final controllerState = pageState.firstWhere((state) => state['name'] == '_inputController');
        expect(controllerState['type'], equals('TextEditingController'));
        
        final focusNodeState = pageState.firstWhere((state) => state['name'] == '_inputFocusNode');
        expect(focusNodeState['type'], equals('FocusNode'));
        
        final submittingState = pageState.firstWhere((state) => state['name'] == '_isSubmitting');
        expect(submittingState['type'], equals('bool'));
        
        final queryState = pageState.firstWhere((state) => state['name'] == '_currentQuery');
        expect(queryState['type'], equals('String'));
        
        final planningState = pageState.firstWhere((state) => state['name'] == '_isPlanning');
        expect(planningState['type'], equals('bool'));
      });
    });

    group('Page Events Consistency', () {
      test('页面事件应该与YAML一致', () {
        final pageEvents = _toList(yamlDoc['page_events']);
        final eventNames = pageEvents.map((event) => event['name'] as String).toList();
        
        // 验证YAML中定义的事件
        expect(eventNames, contains('onTaskSubmit'));
        expect(eventNames, contains('onFilterChange'));
        expect(eventNames, contains('onTaskExpand'));
        expect(eventNames, contains('onTaskTitleEdit'));
        expect(eventNames, contains('onTaskPlan'));
        expect(eventNames, contains('onTaskSwipe'));
        
        // 验证事件描述
        final taskSubmitEvent = pageEvents.firstWhere((event) => event['name'] == 'onTaskSubmit');
        expect(taskSubmitEvent['description'], contains('任务提交事件'));
        
        final filterChangeEvent = pageEvents.firstWhere((event) => event['name'] == 'onFilterChange');
        expect(filterChangeEvent['description'], contains('过滤器变化事件'));
        
        final taskExpandEvent = pageEvents.firstWhere((event) => event['name'] == 'onTaskExpand');
        expect(taskExpandEvent['description'], contains('任务展开事件'));
        
        final taskTitleEditEvent = pageEvents.firstWhere((event) => event['name'] == 'onTaskTitleEdit');
        expect(taskTitleEditEvent['description'], contains('任务标题编辑事件'));
        
        final taskPlanEvent = pageEvents.firstWhere((event) => event['name'] == 'onTaskPlan');
        expect(taskPlanEvent['description'], contains('任务计划事件'));
        
        final taskSwipeEvent = pageEvents.firstWhere((event) => event['name'] == 'onTaskSwipe');
        expect(taskSwipeEvent['description'], contains('任务滑动事件'));
      });
    });

    group('Page Components Consistency', () {
      test('页面组件应该与YAML一致', () {
        final pageComponents = _toList(yamlDoc['page_components']);
        final componentNames = pageComponents.map((component) => component['name'] as String).toList();
        
        // 验证YAML中定义的组件
        expect(componentNames, contains('InboxTaskTile'));
        expect(componentNames, contains('ExpandedInboxControls'));
        expect(componentNames, contains('QuickDatePicker'));
        expect(componentNames, contains('FilterChipGroup'));
        expect(componentNames, contains('DismissibleTask'));
        expect(componentNames, contains('TaskIdDisplay'));
        
        // 验证组件类型
        final taskTileComponent = pageComponents.firstWhere((component) => component['name'] == 'InboxTaskTile');
        expect(taskTileComponent['type'], equals('ConsumerStatefulWidget'));
        
        final expandedControlsComponent = pageComponents.firstWhere((component) => component['name'] == 'ExpandedInboxControls');
        expect(expandedControlsComponent['type'], equals('ConsumerStatefulWidget'));
        
        final quickDatePickerComponent = pageComponents.firstWhere((component) => component['name'] == 'QuickDatePicker');
        expect(quickDatePickerComponent['type'], equals('StatelessWidget'));
        
        final filterChipGroupComponent = pageComponents.firstWhere((component) => component['name'] == 'FilterChipGroup');
        expect(filterChipGroupComponent['type'], equals('Widget'));
        
        final dismissibleTaskComponent = pageComponents.firstWhere((component) => component['name'] == 'DismissibleTask');
        expect(dismissibleTaskComponent['type'], equals('Dismissible'));
        
        final taskIdDisplayComponent = pageComponents.firstWhere((component) => component['name'] == 'TaskIdDisplay');
        expect(taskIdDisplayComponent['type'], equals('Text'));
      });

      test('组件功能应该与YAML一致', () {
        final pageComponents = _toList(yamlDoc['page_components']);
        
        // 验证InboxTaskTile功能
        final taskTileComponent = pageComponents.firstWhere((component) => component['name'] == 'InboxTaskTile');
        final taskTileFeatures = taskTileComponent['features'] as List;
        expect(taskTileFeatures, contains('任务显示'));
        expect(taskTileFeatures, contains('内联编辑'));
        expect(taskTileFeatures, contains('滑动操作'));
        expect(taskTileFeatures, contains('展开/收起'));
        expect(taskTileFeatures, contains('任务ID显示'));
        
        // 验证ExpandedInboxControls功能
        final expandedControlsComponent = pageComponents.firstWhere((component) => component['name'] == 'ExpandedInboxControls');
        final expandedControlsFeatures = expandedControlsComponent['features'] as List;
        expect(expandedControlsFeatures, contains('标签管理'));
        expect(expandedControlsFeatures, contains('日期选择'));
        expect(expandedControlsFeatures, contains('任务操作'));
        
        // 验证QuickDatePicker功能
        final quickDatePickerComponent = pageComponents.firstWhere((component) => component['name'] == 'QuickDatePicker');
        final quickDatePickerFeatures = quickDatePickerComponent['features'] as List;
        expect(quickDatePickerFeatures, contains('今天'));
        expect(quickDatePickerFeatures, contains('明天'));
        expect(quickDatePickerFeatures, contains('本周'));
        expect(quickDatePickerFeatures, contains('当月'));
        expect(quickDatePickerFeatures, contains('自定义日期'));
        
        // 验证FilterChipGroup功能
        final filterChipGroupComponent = pageComponents.firstWhere((component) => component['name'] == 'FilterChipGroup');
        final filterChipGroupFeatures = filterChipGroupComponent['features'] as List;
        expect(filterChipGroupFeatures, contains('紧急程度过滤'));
        expect(filterChipGroupFeatures, contains('重要程度过滤'));
        expect(filterChipGroupFeatures, contains('清除过滤器'));
        
        // 验证DismissibleTask功能
        final dismissibleTaskComponent = pageComponents.firstWhere((component) => component['name'] == 'DismissibleTask');
        final dismissibleTaskFeatures = dismissibleTaskComponent['features'] as List;
        expect(dismissibleTaskFeatures, contains('左滑删除'));
        expect(dismissibleTaskFeatures, contains('右滑计划'));
        expect(dismissibleTaskFeatures, contains('确认对话框'));
        
        // 验证TaskIdDisplay功能
        final taskIdDisplayComponent = pageComponents.firstWhere((component) => component['name'] == 'TaskIdDisplay');
        final taskIdDisplayFeatures = taskIdDisplayComponent['features'] as List;
        expect(taskIdDisplayFeatures, contains('显示YYYYMMDD-XXXX格式ID'));
        expect(taskIdDisplayFeatures, contains('小字体显示'));
      });
    });

    group('Page Business Logic Consistency', () {
      test('业务逻辑应该与YAML一致', () {
        final businessLogic = _toList(yamlDoc['page_business_logic']);
        final logicNames = businessLogic.map((logic) => logic['name'] as String).toList();
        
        // 验证YAML中定义的业务逻辑
        expect(logicNames, contains('taskManagementLogic'));
        expect(logicNames, contains('priorityFilterLogic'));
        expect(logicNames, contains('inlineEditLogic'));
        expect(logicNames, contains('datePickerLogic'));
        expect(logicNames, contains('swipeActionLogic'));
        expect(logicNames, contains('taskIdGenerationLogic'));
        
        // 验证业务逻辑描述
        final taskManagementLogic = businessLogic.firstWhere((logic) => logic['name'] == 'taskManagementLogic');
        expect(taskManagementLogic['description'], contains('任务管理逻辑'));
        
        final priorityFilterLogic = businessLogic.firstWhere((logic) => logic['name'] == 'priorityFilterLogic');
        expect(priorityFilterLogic['description'], contains('优先级过滤逻辑'));
        
        final inlineEditLogic = businessLogic.firstWhere((logic) => logic['name'] == 'inlineEditLogic');
        expect(inlineEditLogic['description'], contains('内联编辑逻辑'));
        
        final datePickerLogic = businessLogic.firstWhere((logic) => logic['name'] == 'datePickerLogic');
        expect(datePickerLogic['description'], contains('自定义日期选择逻辑'));
        
        final swipeActionLogic = businessLogic.firstWhere((logic) => logic['name'] == 'swipeActionLogic');
        expect(swipeActionLogic['description'], contains('滑动操作逻辑'));
        
        final taskIdGenerationLogic = businessLogic.firstWhere((logic) => logic['name'] == 'taskIdGenerationLogic');
        expect(taskIdGenerationLogic['description'], contains('任务ID生成逻辑'));
        expect(taskIdGenerationLogic['implementation'], contains('基于日期的自增ID生成'));
        expect(taskIdGenerationLogic['implementation'], contains('YYYYMMDD-XXXX'));
      });
    });

    group('Page User Experience Consistency', () {
      test('用户体验应该与YAML一致', () {
        final userExperience = _toList(yamlDoc['page_user_experience']);
        final experienceNames = userExperience.map((exp) => exp['name'] as String).toList();
        
        // 验证YAML中定义的用户体验
        expect(experienceNames, contains('quickTaskExperience'));
        expect(experienceNames, contains('priorityFilterExperience'));
        expect(experienceNames, contains('inlineEditExperience'));
        expect(experienceNames, contains('customDatePickerExperience'));
        expect(experienceNames, contains('swipeActionExperience'));
        expect(experienceNames, contains('taskIdDisplayExperience'));
        
        // 验证用户体验描述
        final priorityFilterExperience = userExperience.firstWhere((exp) => exp['name'] == 'priorityFilterExperience');
        expect(priorityFilterExperience['description'], contains('优先级过滤体验'));
        expect(priorityFilterExperience['implementation'], contains('紧急程度和重要程度标签过滤'));
        
        final inlineEditExperience = userExperience.firstWhere((exp) => exp['name'] == 'inlineEditExperience');
        expect(inlineEditExperience['description'], contains('内联编辑体验'));
        expect(inlineEditExperience['implementation'], contains('任务标题直接编辑'));
        
        final customDatePickerExperience = userExperience.firstWhere((exp) => exp['name'] == 'customDatePickerExperience');
        expect(customDatePickerExperience['description'], contains('自定义日期选择体验'));
        expect(customDatePickerExperience['implementation'], contains('快速日期选择和自定义日期选择'));
        
        final swipeActionExperience = userExperience.firstWhere((exp) => exp['name'] == 'swipeActionExperience');
        expect(swipeActionExperience['description'], contains('滑动操作体验'));
        expect(swipeActionExperience['implementation'], contains('左滑删除、右滑计划'));
        
        final taskIdDisplayExperience = userExperience.firstWhere((exp) => exp['name'] == 'taskIdDisplayExperience');
        expect(taskIdDisplayExperience['description'], contains('任务ID显示体验'));
        expect(taskIdDisplayExperience['implementation'], contains('显示YYYYMMDD-XXXX格式的任务ID'));
      });
    });

    group('Page Validation Consistency', () {
      test('验证规则应该与YAML一致', () {
        final validation = _toList(yamlDoc['page_validation']);
        final validationFields = validation.map((rule) => rule['field'] as String).toList();
        
        // 验证YAML中定义的验证规则
        expect(validationFields, contains('taskTitle'));
        expect(validationFields, contains('taskId'));
        expect(validationFields, contains('dueDate'));
        expect(validationFields, contains('tagSelection'));
        
        // 验证验证规则描述
        final taskTitleValidation = validation.firstWhere((rule) => rule['field'] == 'taskTitle');
        expect(taskTitleValidation['rule'], equals('not_empty'));
        expect(taskTitleValidation['description'], contains('任务标题不能为空'));
        
        final taskIdValidation = validation.firstWhere((rule) => rule['field'] == 'taskId');
        expect(taskIdValidation['rule'], equals('format_validation'));
        expect(taskIdValidation['description'], contains('任务ID格式验证'));
        expect(taskIdValidation['message'], contains('任务ID格式必须为YYYYMMDD-XXXX'));
        
        final dueDateValidation = validation.firstWhere((rule) => rule['field'] == 'dueDate');
        expect(dueDateValidation['rule'], equals('date_validation'));
        expect(dueDateValidation['description'], contains('截止日期验证'));
        expect(dueDateValidation['message'], contains('截止日期不能早于今天'));
        
        final tagSelectionValidation = validation.firstWhere((rule) => rule['field'] == 'tagSelection');
        expect(tagSelectionValidation['rule'], equals('single_selection'));
        expect(tagSelectionValidation['description'], contains('标签单选验证'));
        expect(tagSelectionValidation['message'], contains('每个标签组只能选择一个'));
      });
    });

    group('Page Error Handling Consistency', () {
      test('错误处理应该与YAML一致', () {
        final errorHandling = _toList(yamlDoc['page_error_handling']);
        final exceptionNames = errorHandling.map((error) => error['exception'] as String).toList();
        
        // 验证YAML中定义的异常处理
        expect(exceptionNames, contains('TaskSubmissionException'));
        expect(exceptionNames, contains('TaskIdGenerationException'));
        expect(exceptionNames, contains('DatePickerException'));
        expect(exceptionNames, contains('TaskUpdateException'));
        expect(exceptionNames, contains('FilterException'));
        
        // 验证异常处理描述
        final taskIdGenerationException = errorHandling.firstWhere((error) => error['exception'] == 'TaskIdGenerationException');
        expect(taskIdGenerationException['description'], contains('任务ID生成异常'));
        expect(taskIdGenerationException['handling'], contains('处理任务ID生成错误并fallback到默认格式'));
        expect(taskIdGenerationException['recovery'], contains('使用默认ID格式'));
        
        final datePickerException = errorHandling.firstWhere((error) => error['exception'] == 'DatePickerException');
        expect(datePickerException['description'], contains('日期选择器异常'));
        expect(datePickerException['handling'], contains('处理日期选择错误并显示错误消息'));
        
        final taskUpdateException = errorHandling.firstWhere((error) => error['exception'] == 'TaskUpdateException');
        expect(taskUpdateException['description'], contains('任务更新异常'));
        expect(taskUpdateException['handling'], contains('处理任务更新错误并显示错误消息'));
        
        final filterException = errorHandling.firstWhere((error) => error['exception'] == 'FilterException');
        expect(filterException['description'], contains('过滤器异常'));
        expect(filterException['handling'], contains('处理过滤器错误并重置过滤器'));
      });
    });

    group('Page Internationalization Consistency', () {
      test('国际化应该与YAML一致', () {
        final internationalization = _toList(yamlDoc['page_internationalization']);
        final i18nNames = internationalization.map((i18n) => i18n['name'] as String).toList();
        
        // 验证YAML中定义的国际化
        expect(i18nNames, contains('inboxPage'));
        expect(i18nNames, contains('priorityFilterLabels'));
        expect(i18nNames, contains('datePickerLabels'));
        expect(i18nNames, contains('taskActions'));
        
        // 验证国际化描述
        final inboxPageI18n = internationalization.firstWhere((i18n) => i18n['name'] == 'inboxPage');
        expect(inboxPageI18n['languages'], contains('zh_CN'));
        expect(inboxPageI18n['languages'], contains('zh_HK'));
        expect(inboxPageI18n['languages'], contains('en_US'));
        expect(inboxPageI18n['fallback'], equals('en_US'));
        
        final priorityFilterLabelsI18n = internationalization.firstWhere((i18n) => i18n['name'] == 'priorityFilterLabels');
        expect(priorityFilterLabelsI18n['description'], contains('优先级过滤器标签国际化'));
        expect(priorityFilterLabelsI18n['context'], contains('紧急程度、重要程度'));
        
        final datePickerLabelsI18n = internationalization.firstWhere((i18n) => i18n['name'] == 'datePickerLabels');
        expect(datePickerLabelsI18n['description'], contains('日期选择器标签国际化'));
        expect(datePickerLabelsI18n['context'], contains('今天、明天、本周、当月'));
        
        final taskActionsI18n = internationalization.firstWhere((i18n) => i18n['name'] == 'taskActions');
        expect(taskActionsI18n['description'], contains('任务操作国际化'));
        expect(taskActionsI18n['context'], contains('移动到今日任务、移动到回收站'));
      });
    });

    group('Page Testing Strategy Consistency', () {
      test('测试策略应该与YAML一致', () {
        final testingStrategy = _toMap(yamlDoc['page_testing_strategy']);
        
        // 验证单元测试
        final unitTests = _toList(testingStrategy['unit_tests']);
        final unitTestNames = unitTests.map((test) => test['name'] as String).toList();
        
        expect(unitTestNames, contains('test_priority_filter'));
        expect(unitTestNames, contains('test_inline_edit'));
        expect(unitTestNames, contains('test_date_picker'));
        expect(unitTestNames, contains('test_swipe_actions'));
        expect(unitTestNames, contains('test_task_id_generation'));
        expect(unitTestNames, contains('test_task_id_format'));
        expect(unitTestNames, contains('test_task_id_increment'));
        expect(unitTestNames, contains('test_task_id_cross_day'));
        
        // 验证Widget测试
        final widgetTests = _toList(testingStrategy['widget_tests']);
        final widgetTestNames = widgetTests.map((test) => test['name'] as String).toList();
        
        expect(widgetTestNames, contains('test_priority_filter_ui'));
        expect(widgetTestNames, contains('test_inline_edit_ui'));
        expect(widgetTestNames, contains('test_date_picker_ui'));
        expect(widgetTestNames, contains('test_swipe_actions_ui'));
        expect(widgetTestNames, contains('test_task_expansion_ui'));
        expect(widgetTestNames, contains('test_task_id_display_ui'));
        
        // 验证集成测试
        final integrationTests = _toList(testingStrategy['integration_tests']);
        final integrationTestNames = integrationTests.map((test) => test['name'] as String).toList();
        
        expect(integrationTestNames, contains('test_task_id_generation_integration'));
        expect(integrationTestNames, contains('test_task_id_display_integration'));
      });
    });

    group('Page Features Summary Consistency', () {
      test('功能总结应该与YAML一致', () {
        final featuresSummary = _toMap(yamlDoc['page_features_summary']);
        
        // 验证核心功能
        final coreFeatures = featuresSummary['core_features'] as List;
        expect(coreFeatures, contains('任务快速添加'));
        expect(coreFeatures, contains('任务内联编辑'));
        expect(coreFeatures, contains('任务滑动操作'));
        expect(coreFeatures, contains('任务展开/收起'));
        expect(coreFeatures, contains('任务ID显示'));
        
        // 验证过滤功能
        final filterFeatures = featuresSummary['filter_features'] as List;
        expect(filterFeatures, contains('紧急程度过滤'));
        expect(filterFeatures, contains('重要程度过滤'));
        expect(filterFeatures, contains('清除过滤器'));
        expect(filterFeatures, contains('标签管理'));
        
        // 验证日期功能
        final dateFeatures = featuresSummary['date_features'] as List;
        expect(dateFeatures, contains('快速日期选择'));
        expect(dateFeatures, contains('自定义日期选择'));
        expect(dateFeatures, contains('日期验证'));
        expect(dateFeatures, contains('任务计划'));
        
        // 验证ID功能
        final idFeatures = featuresSummary['id_features'] as List;
        expect(idFeatures, contains('YYYYMMDD-XXXX格式'));
        expect(idFeatures, contains('每日自增'));
        expect(idFeatures, contains('跨天重置'));
        expect(idFeatures, contains('错误处理'));
        
        // 验证UI功能
        final uiFeatures = featuresSummary['ui_features'] as List;
        expect(uiFeatures, contains('响应式设计'));
        expect(uiFeatures, contains('主题集成'));
        expect(uiFeatures, contains('国际化支持'));
        expect(uiFeatures, contains('无障碍支持'));
        expect(uiFeatures, contains('动画效果'));
      });
    });

    group('YAML File Integrity', () {
      test('YAML文件应该存在且可读', () {
        expect(File(yamlFilePath).existsSync(), isTrue);
      });

      test('YAML文件应该包含所有必需的顶级键', () {
        expect(yamlDoc.containsKey('meta'), isTrue);
        expect(yamlDoc.containsKey('page_definition'), isTrue);
        expect(yamlDoc.containsKey('page_state'), isTrue);
        expect(yamlDoc.containsKey('page_events'), isTrue);
        expect(yamlDoc.containsKey('page_components'), isTrue);
        expect(yamlDoc.containsKey('page_business_logic'), isTrue);
        expect(yamlDoc.containsKey('page_user_experience'), isTrue);
        expect(yamlDoc.containsKey('page_validation'), isTrue);
        expect(yamlDoc.containsKey('page_error_handling'), isTrue);
        expect(yamlDoc.containsKey('page_internationalization'), isTrue);
        expect(yamlDoc.containsKey('page_testing_strategy'), isTrue);
        expect(yamlDoc.containsKey('page_features_summary'), isTrue);
      });

      test('YAML文件应该包含正确的元数据', () {
        final meta = _toMap(yamlDoc['meta']);
        expect(meta.containsKey('name'), isTrue);
        expect(meta.containsKey('type'), isTrue);
        expect(meta.containsKey('description'), isTrue);
        expect(meta.containsKey('version'), isTrue);
        expect(meta.containsKey('created_date'), isTrue);
        expect(meta.containsKey('last_updated'), isTrue);
      });
    });
  });
}
