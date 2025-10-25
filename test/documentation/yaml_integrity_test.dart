import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:flutter_test/flutter_test.dart';
import 'yaml_test_helper.dart';

class YAMLIntegrityTest {
  static final List<String> requiredYAMLFiles = [
    'documents/architecture/widgets/navigation_destinations.yaml',
    'documents/architecture/widgets/drawer_menu.yaml',
    'documents/architecture/widgets/responsive_navigation.yaml',
    'documents/architecture/widgets/main_drawer.yaml',
    'documents/architecture/widgets/page_app_bar.yaml',
    'documents/architecture/widgets/create_task_dialog.yaml',
    'documents/architecture/widgets/widgets.yaml',
  ];

  static Future<void> validateYAMLFiles() async {
    for (final filePath in requiredYAMLFiles) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Required YAML file not found: $filePath');
      }
      
      try {
        final content = await file.readAsString();
        loadYaml(content);
      } catch (e) {
        throw Exception('Invalid YAML syntax in $filePath: $e');
      }
    }
  }

  static Future<void> validateYAMLStructure() async {
    // 验证 widgets.yaml 的完整性
    final widgetsFile = File('documents/architecture/widgets/widgets.yaml');
    final widgetsYaml = Map<String, dynamic>.from(loadYaml(await widgetsFile.readAsString()) as Map);
    
    final components = yamlToList(widgetsYaml['components']);
    
    // 验证所有组件都有对应的 YAML 文件
    for (final component in components) {
      final fileName = component['file'];
      final filePath = 'documents/architecture/widgets/$fileName';
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Component YAML file not found: $filePath');
      }
    }
  }

  static Future<void> validateNavigationComponents() async {
    // 验证导航组件的完整性
    final widgetsFile = File('documents/architecture/widgets/widgets.yaml');
    final widgetsYaml = Map<String, dynamic>.from(loadYaml(await widgetsFile.readAsString()) as Map);
    
    final navigationComponents = yamlToList(widgetsYaml['categories']['navigation']['components']);
    final expectedNavigationComponents = [
      'NavigationDestinations',
      'DrawerMenu',
      'AppNavigationBar',
      'ResponsiveNavigation',
      'AppShell',
      'AppRouter',
      'MainDrawer',
      'PageAppBar',
    ];
    
    for (final expectedComponent in expectedNavigationComponents) {
      if (!navigationComponents.contains(expectedComponent)) {
        throw Exception('Navigation component $expectedComponent missing in widgets.yaml');
      }
    }
  }

  static Future<void> validateBusinessComponents() async {
    // 验证业务组件的完整性
    final widgetsFile = File('documents/architecture/widgets/widgets.yaml');
    final widgetsYaml = Map<String, dynamic>.from(loadYaml(await widgetsFile.readAsString()) as Map);
    
    final businessComponents = yamlToList(widgetsYaml['categories']['business']['components']);
    final expectedBusinessComponents = [
      'DashboardMetricCard',
      'PrimaryActionButton',
      'PersistentInboxInput',
      'ChipToggleGroup',
      'TaskSectionList',
      'FocusTimerDisplay',
      'CreateTaskDialog',
    ];
    
    for (final expectedComponent in expectedBusinessComponents) {
      if (!businessComponents.contains(expectedComponent)) {
        throw Exception('Business component $expectedComponent missing in widgets.yaml');
      }
    }
  }

  static Future<void> validateDependencies() async {
    // 验证依赖关系的完整性
    final widgetsFile = File('documents/architecture/widgets/widgets.yaml');
    final widgetsYaml = Map<String, dynamic>.from(loadYaml(await widgetsFile.readAsString()) as Map);
    
    final dependencies = Map<String, dynamic>.from(widgetsYaml['dependencies'] as Map);
    final expectedDependencies = [
      'NavigationDestinations',
      'DrawerMenu',
      'AppNavigationBar',
      'ResponsiveNavigation',
      'AppShell',
      'AppRouter',
      'MainDrawer',
      'PageAppBar',
      'CreateTaskDialog',
    ];
    
    for (final expectedDep in expectedDependencies) {
      if (!dependencies.containsKey(expectedDep)) {
        throw Exception('Dependencies missing for $expectedDep in widgets.yaml');
      }
    }
  }

  static Future<void> validateTestCoverage() async {
    // 验证测试覆盖率的完整性
    final widgetsFile = File('documents/architecture/widgets/widgets.yaml');
    final widgetsYaml = Map<String, dynamic>.from(loadYaml(await widgetsFile.readAsString()) as Map);
    
    final testing = Map<String, dynamic>.from(widgetsYaml['testing'] as Map);
    final expectedTestTypes = ['unit_tests', 'widget_tests', 'integration_tests'];
    
    for (final testType in expectedTestTypes) {
      if (!testing.containsKey(testType)) {
        throw Exception('Test type $testType missing in widgets.yaml');
      }
    }
  }

  static Future<void> validateNavigationDestinationsYAML() async {
    // 验证 NavigationDestinations YAML 的完整性
    final navDestFile = File('documents/architecture/widgets/navigation_destinations.yaml');
    final navDestYaml = Map<String, dynamic>.from(loadYaml(await navDestFile.readAsString()) as Map);
    
    // 验证必需的属性
    final requiredProperties = ['values', 'icon', 'selectedIcon', 'route'];
    final properties = yamlToList(navDestYaml['properties']);
    for (final prop in requiredProperties) {
      final property = properties.firstWhere(
        (p) => p['name'] == prop,
        orElse: () => throw Exception('Required property $prop missing in NavigationDestinations YAML'),
      );
      expect(property, isNotNull, reason: 'Property $prop should be defined');
    }
    
    // 验证枚举值
    final valuesProp = properties.firstWhere(
      (p) => p['name'] == 'values',
      orElse: () => throw Exception('Values property missing in NavigationDestinations YAML'),
    );
    final values = yamlToList(valuesProp['values']);
    expect(values, isNotEmpty, reason: 'NavigationDestinations should have values');
    
    // 验证图标定义
    final iconProp = properties.firstWhere(
      (p) => p['name'] == 'icon',
      orElse: () => throw Exception('Icon property missing in NavigationDestinations YAML'),
    );
    final icons = Map<String, dynamic>.from(iconProp['values'] as Map);
    for (final value in values) {
      if (!icons.containsKey(value)) {
        throw Exception('Icon definition missing for $value in NavigationDestinations YAML');
      }
    }
    
    // 验证路由定义
    final routeProp = properties.firstWhere(
      (p) => p['name'] == 'route',
      orElse: () => throw Exception('Route property missing in NavigationDestinations YAML'),
    );
    final routes = Map<String, dynamic>.from(routeProp['values'] as Map);
    for (final value in values) {
      if (!routes.containsKey(value)) {
        throw Exception('Route definition missing for $value in NavigationDestinations YAML');
      }
    }
  }

  static Future<void> validateDrawerMenuYAML() async {
    // 验证 DrawerMenu YAML 的完整性
    final drawerMenuFile = File('documents/architecture/widgets/drawer_menu.yaml');
    final drawerMenuYaml = Map<String, dynamic>.from(loadYaml(await drawerMenuFile.readAsString()) as Map);
    
    // 验证必需的属性
    final properties = yamlToList(drawerMenuYaml['properties']);
    final requiredProperties = ['displayMode', 'selectedIndex', 'onDestinationSelected', 'onClose'];
    for (final prop in requiredProperties) {
      final property = properties.firstWhere(
        (p) => p['name'] == prop,
        orElse: () => throw Exception('Required property $prop missing in DrawerMenu YAML'),
      );
      expect(property['type'], isA<String>(), reason: 'Property type should be defined for $prop');
    }
    
    // 验证必需的方法
    final methods = yamlToList(drawerMenuYaml['methods']);
    final requiredMethods = ['_getDrawerWidth', '_showCreateTaskDialog'];
    for (final method in requiredMethods) {
      final methodDef = methods.firstWhere(
        (m) => m['name'] == method,
        orElse: () => throw Exception('Required method $method missing in DrawerMenu YAML'),
      );
      expect(methodDef['return_type'], isA<String>(), reason: 'Return type should be defined for $method');
    }
  }

  static Future<void> validateResponsiveNavigationYAML() async {
    // 验证 ResponsiveNavigation YAML 的完整性
    final responsiveNavFile = File('documents/architecture/widgets/responsive_navigation.yaml');
    final responsiveNavYaml = Map<String, dynamic>.from(loadYaml(await responsiveNavFile.readAsString()) as Map);
    
    // 验证必需的属性
    final properties = yamlToList(responsiveNavYaml['properties']);
    final requiredProperties = ['selectedIndex', 'onDestinationSelected', 'child'];
    for (final prop in requiredProperties) {
      final property = properties.firstWhere(
        (p) => p['name'] == prop,
        orElse: () => throw Exception('Required property $prop missing in ResponsiveNavigation YAML'),
      );
      expect(property['type'], isA<String>(), reason: 'Property type should be defined for $prop');
    }
    
    // 验证必需的方法
    final methods = yamlToList(responsiveNavYaml['methods']);
    final requiredMethods = ['_showCreateTaskDialog', '_buildBottomSheet'];
    for (final method in requiredMethods) {
      final methodDef = methods.firstWhere(
        (m) => m['name'] == method,
        orElse: () => throw Exception('Required method $method missing in ResponsiveNavigation YAML'),
      );
      expect(methodDef['return_type'], isA<String>(), reason: 'Return type should be defined for $method');
    }
  }
}

// 主测试组
void main() {
  group('YAML Integrity Tests', () {
    test('All required YAML files should exist', () async {
      await YAMLIntegrityTest.validateYAMLFiles();
    });

    test('YAML files should have valid syntax', () async {
      await YAMLIntegrityTest.validateYAMLFiles();
    });

    test('YAML structure should be complete', () async {
      await YAMLIntegrityTest.validateYAMLStructure();
    });

    test('Navigation components should be complete', () async {
      await YAMLIntegrityTest.validateNavigationComponents();
    });

    test('Business components should be complete', () async {
      await YAMLIntegrityTest.validateBusinessComponents();
    });

    test('Dependencies should be complete', () async {
      await YAMLIntegrityTest.validateDependencies();
    });

    test('Test coverage should be complete', () async {
      await YAMLIntegrityTest.validateTestCoverage();
    });

    test('NavigationDestinations YAML should be complete', () async {
      await YAMLIntegrityTest.validateNavigationDestinationsYAML();
    });

    test('DrawerMenu YAML should be complete', () async {
      await YAMLIntegrityTest.validateDrawerMenuYAML();
    });

    test('ResponsiveNavigation YAML should be complete', () async {
      await YAMLIntegrityTest.validateResponsiveNavigationYAML();
    });
  });
}
