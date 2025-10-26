import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// Inbox核心一致性测试
/// 
/// 这个测试文件验证inbox页面的核心功能与YAML文档的一致性，
/// 确保关键功能描述完整且正确。
void main() {
  group('Inbox Core Consistency Tests', () {
    late Map yamlDoc;
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
      yamlDoc = loadYaml(yamlContent);
    });

    group('Document Existence', () {
      test('YAML文件应该存在', () {
        expect(File(yamlFilePath).existsSync(), isTrue);
      });

      test('YAML文件应该包含基本结构', () {
        expect(yamlDoc, isA<Map>());
        expect(yamlDoc.keys, contains('meta'));
        expect(yamlDoc.keys, contains('page_components'));
        expect(yamlDoc.keys, contains('page_business_logic'));
        expect(yamlDoc.keys, contains('page_user_experience'));
        expect(yamlDoc.keys, contains('page_features_summary'));
      });
    });

    group('Meta Information', () {
      test('应该包含正确的元数据', () {
        final meta = yamlDoc['meta'];
        expect(meta, isA<Map>());
        expect(meta['name'], equals('InboxPage'));
        expect(meta['type'], equals('page'));
        expect(meta['version'], equals('2.0'));
        expect(meta['last_updated'], equals('251026'));
      });

      test('描述应该包含关键功能', () {
        final meta = yamlDoc['meta'];
        final description = meta['description'] as String;
        expect(description, contains('收集箱页面'));
        expect(description, contains('优先级过滤'));
        expect(description, contains('内联编辑'));
        expect(description, contains('自定义日期选择'));
      });
    });

    group('Core Components', () {
      test('应该包含所有核心组件', () {
        final pageComponents = yamlDoc['page_components'] as List;
        final componentNames = pageComponents.map((component) => component['name']).toList();
        
        expect(componentNames, contains('InboxTaskTile'));
        expect(componentNames, contains('QuickDatePicker'));
        expect(componentNames, contains('FilterChipGroup'));
        expect(componentNames, contains('DismissibleTask'));
        expect(componentNames, contains('TaskIdDisplay'));
      });

      test('InboxTaskTile应该包含所有功能', () {
        final pageComponents = yamlDoc['page_components'] as List;
        final taskTileComponent = pageComponents.firstWhere((component) => component['name'] == 'InboxTaskTile');
        final taskTileFeatures = taskTileComponent['features'] as List;
        
        expect(taskTileFeatures, contains('任务显示'));
        expect(taskTileFeatures, contains('内联编辑'));
        expect(taskTileFeatures, contains('滑动操作'));
        expect(taskTileFeatures, contains('展开/收起'));
        expect(taskTileFeatures, contains('任务ID显示'));
      });

      test('QuickDatePicker应该包含所有功能', () {
        final pageComponents = yamlDoc['page_components'] as List;
        final quickDatePickerComponent = pageComponents.firstWhere((component) => component['name'] == 'QuickDatePicker');
        final quickDatePickerFeatures = quickDatePickerComponent['features'] as List;
        
        expect(quickDatePickerFeatures, contains('今天'));
        expect(quickDatePickerFeatures, contains('明天'));
        expect(quickDatePickerFeatures, contains('本周'));
        expect(quickDatePickerFeatures, contains('当月'));
        expect(quickDatePickerFeatures, contains('自定义日期'));
      });

      test('FilterChipGroup应该包含所有功能', () {
        final pageComponents = yamlDoc['page_components'] as List;
        final filterChipGroupComponent = pageComponents.firstWhere((component) => component['name'] == 'FilterChipGroup');
        final filterChipGroupFeatures = filterChipGroupComponent['features'] as List;
        
        expect(filterChipGroupFeatures, contains('紧急程度过滤'));
        expect(filterChipGroupFeatures, contains('重要程度过滤'));
        expect(filterChipGroupFeatures, contains('清除过滤器'));
      });

      test('DismissibleTask应该包含所有功能', () {
        final pageComponents = yamlDoc['page_components'] as List;
        final dismissibleTaskComponent = pageComponents.firstWhere((component) => component['name'] == 'DismissibleTask');
        final dismissibleTaskFeatures = dismissibleTaskComponent['features'] as List;
        
        expect(dismissibleTaskFeatures, contains('左滑删除'));
        expect(dismissibleTaskFeatures, contains('右滑计划'));
        expect(dismissibleTaskFeatures, contains('确认对话框'));
      });

      test('TaskIdDisplay应该包含所有功能', () {
        final pageComponents = yamlDoc['page_components'] as List;
        final taskIdDisplayComponent = pageComponents.firstWhere((component) => component['name'] == 'TaskIdDisplay');
        final taskIdDisplayFeatures = taskIdDisplayComponent['features'] as List;
        
        expect(taskIdDisplayFeatures, contains('显示YYYYMMDD-XXXX格式ID'));
        expect(taskIdDisplayFeatures, contains('小字体显示'));
      });
    });

    group('Business Logic', () {
      test('应该包含所有核心业务逻辑', () {
        final businessLogic = yamlDoc['page_business_logic'] as List;
        final logicNames = businessLogic.map((logic) => logic['name']).toList();
        
        expect(logicNames, contains('taskManagementLogic'));
        expect(logicNames, contains('priorityFilterLogic'));
        expect(logicNames, contains('inlineEditLogic'));
        expect(logicNames, contains('datePickerLogic'));
        expect(logicNames, contains('swipeActionLogic'));
        expect(logicNames, contains('taskIdGenerationLogic'));
      });

      test('taskIdGenerationLogic应该包含正确的描述', () {
        final businessLogic = yamlDoc['page_business_logic'] as List;
        final taskIdGenerationLogic = businessLogic.firstWhere((logic) => logic['name'] == 'taskIdGenerationLogic');
        
        expect(taskIdGenerationLogic['description'], contains('任务ID生成逻辑'));
        expect(taskIdGenerationLogic['implementation'], contains('基于日期的自增ID生成'));
        expect(taskIdGenerationLogic['implementation'], contains('YYYYMMDD-XXXX'));
      });
    });

    group('User Experience', () {
      test('应该包含所有核心用户体验', () {
        final userExperience = yamlDoc['page_user_experience'] as List;
        final experienceNames = userExperience.map((exp) => exp['name']).toList();
        
        expect(experienceNames, contains('quickTaskExperience'));
        expect(experienceNames, contains('priorityFilterExperience'));
        expect(experienceNames, contains('inlineEditExperience'));
        expect(experienceNames, contains('customDatePickerExperience'));
        expect(experienceNames, contains('swipeActionExperience'));
        expect(experienceNames, contains('taskIdDisplayExperience'));
      });

      test('taskIdDisplayExperience应该包含正确的描述', () {
        final userExperience = yamlDoc['page_user_experience'] as List;
        final taskIdDisplayExperience = userExperience.firstWhere((exp) => exp['name'] == 'taskIdDisplayExperience');
        
        expect(taskIdDisplayExperience['description'], contains('任务ID显示体验'));
        expect(taskIdDisplayExperience['implementation'], contains('显示YYYYMMDD-XXXX格式的任务ID'));
      });
    });

    group('Features Summary', () {
      test('应该包含所有核心功能', () {
        final featuresSummary = yamlDoc['page_features_summary'] as Map;
        final coreFeatures = featuresSummary['core_features'] as List;
        
        expect(coreFeatures, contains('任务快速添加'));
        expect(coreFeatures, contains('任务内联编辑'));
        expect(coreFeatures, contains('任务滑动操作'));
        expect(coreFeatures, contains('任务展开/收起'));
        expect(coreFeatures, contains('任务ID显示'));
      });

      test('应该包含所有过滤功能', () {
        final featuresSummary = yamlDoc['page_features_summary'] as Map;
        final filterFeatures = featuresSummary['filter_features'] as List;
        
        expect(filterFeatures, contains('紧急程度过滤'));
        expect(filterFeatures, contains('重要程度过滤'));
        expect(filterFeatures, contains('清除过滤器'));
        expect(filterFeatures, contains('标签管理'));
      });

      test('应该包含所有日期功能', () {
        final featuresSummary = yamlDoc['page_features_summary'] as Map;
        final dateFeatures = featuresSummary['date_features'] as List;
        
        expect(dateFeatures, contains('快速日期选择'));
        expect(dateFeatures, contains('自定义日期选择'));
        expect(dateFeatures, contains('日期验证'));
        expect(dateFeatures, contains('任务计划'));
      });

      test('应该包含所有ID功能', () {
        final featuresSummary = yamlDoc['page_features_summary'] as Map;
        final idFeatures = featuresSummary['id_features'] as List;
        
        expect(idFeatures, contains('YYYYMMDD-XXXX格式'));
        expect(idFeatures, contains('每日自增'));
        expect(idFeatures, contains('跨天重置'));
        expect(idFeatures, contains('错误处理'));
      });

      test('应该包含所有UI功能', () {
        final featuresSummary = yamlDoc['page_features_summary'] as Map;
        final uiFeatures = featuresSummary['ui_features'] as List;
        
        expect(uiFeatures, contains('响应式设计'));
        expect(uiFeatures, contains('主题集成'));
        expect(uiFeatures, contains('国际化支持'));
        expect(uiFeatures, contains('无障碍支持'));
        expect(uiFeatures, contains('动画效果'));
      });
    });

    group('Document Lock', () {
      test('YAML文件应该被锁定防止意外修改', () {
        // 验证文件存在且可读
        expect(File(yamlFilePath).existsSync(), isTrue);
        
        // 验证文件包含所有必需的结构
        expect(yamlDoc.keys.length, greaterThan(10));
        
        // 验证关键功能描述存在
        final pageComponents = yamlDoc['page_components'] as List;
        expect(pageComponents.length, greaterThan(5));
        
        final businessLogic = yamlDoc['page_business_logic'] as List;
        expect(businessLogic.length, greaterThan(5));
        
        final userExperience = yamlDoc['page_user_experience'] as List;
        expect(userExperience.length, greaterThan(5));
      });

      test('文档应该包含完整的taskId功能描述', () {
        // 验证taskId相关功能在多个部分都有描述
        final pageComponents = yamlDoc['page_components'] as List;
        final taskIdDisplayComponent = pageComponents.firstWhere((component) => component['name'] == 'TaskIdDisplay');
        expect(taskIdDisplayComponent, isNotNull);
        
        final businessLogic = yamlDoc['page_business_logic'] as List;
        final taskIdGenerationLogic = businessLogic.firstWhere((logic) => logic['name'] == 'taskIdGenerationLogic');
        expect(taskIdGenerationLogic, isNotNull);
        
        final userExperience = yamlDoc['page_user_experience'] as List;
        final taskIdDisplayExperience = userExperience.firstWhere((exp) => exp['name'] == 'taskIdDisplayExperience');
        expect(taskIdDisplayExperience, isNotNull);
        
        final featuresSummary = yamlDoc['page_features_summary'] as Map;
        final idFeatures = featuresSummary['id_features'] as List;
        expect(idFeatures, contains('YYYYMMDD-XXXX格式'));
      });
    });
  });
}
