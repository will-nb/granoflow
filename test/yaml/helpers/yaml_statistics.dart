
/// YAML 测试统计收集器
/// 
/// 用于收集所有测试失败的信息，并在测试结束时输出统计报告
class YamlStatistics {
  static final YamlStatistics _instance = YamlStatistics._internal();
  factory YamlStatistics() => _instance;
  YamlStatistics._internal();

  /// 存储失败的测试信息
  final List<TestFailure> _failures = [];

  /// 记录测试失败
  void recordFailure({
    required String testSuite,
    required String yamlFile,
    required String testName,
    required String issue,
    String? expected,
    String? actual,
    String? suggestion,
  }) {
    _failures.add(TestFailure(
      testSuite: testSuite,
      yamlFile: yamlFile,
      testName: testName,
      issue: issue,
      expected: expected,
      actual: actual,
      suggestion: suggestion,
    ));
  }

  /// 获取所有失败信息
  List<TestFailure> get failures => List.unmodifiable(_failures);

  /// 清空统计
  void clear() {
    _failures.clear();
  }

  /// 输出统计报告
  void printStatistics() {
    if (_failures.isEmpty) {
      return;
    }

    print('');
    print('═' * 80);
    print('📊 YAML 一致性测试统计报告');
    print('═' * 80);
    print('');
    print('❌ 共发现 ${_failures.length} 处不一致：');
    print('');

    // 按测试套件分组
    final bySuite = <String, List<TestFailure>>{};
    for (final failure in _failures) {
      bySuite.putIfAbsent(failure.testSuite, () => []).add(failure);
    }

    // 按 YAML 文件分组
    final byFile = <String, List<TestFailure>>{};
    for (final failure in _failures) {
      byFile.putIfAbsent(failure.yamlFile, () => []).add(failure);
    }

    // 输出按文件分组的统计
    print('📁 按文件分组：');
    print('');
    for (final entry in byFile.entries) {
      final file = entry.key;
      final failures = entry.value;
      print('  📄 $file (${failures.length} 项)');
      
      for (final failure in failures) {
        print('     • ${failure.testName}: ${failure.issue}');
      }
      print('');
    }

    // 输出按测试套件分组的统计
    print('🧪 按测试套件分组：');
    print('');
    for (final entry in bySuite.entries) {
      final suite = entry.key;
      final failures = entry.value;
      print('  📋 $suite (${failures.length} 项)');
      
      // 按文件分组显示
      final filesInSuite = <String, List<TestFailure>>{};
      for (final failure in failures) {
        filesInSuite.putIfAbsent(failure.yamlFile, () => []).add(failure);
      }
      
      for (final fileEntry in filesInSuite.entries) {
        print('     📄 ${fileEntry.key}');
        for (final failure in fileEntry.value) {
          print('        • ${failure.testName}');
          if (failure.expected != null) {
            print('          期望: ${failure.expected}');
          }
          if (failure.actual != null) {
            print('          实际: ${failure.actual}');
          }
          if (failure.suggestion != null) {
            print('          建议: ${failure.suggestion}');
          }
        }
      }
      print('');
    }

    // 输出详细的不一致项列表
    print('📋 详细不一致项列表：');
    print('');
    for (var i = 0; i < _failures.length; i++) {
      final failure = _failures[i];
      print('${i + 1}. 【${failure.testSuite}】${failure.yamlFile}');
      print('   测试: ${failure.testName}');
      print('   问题: ${failure.issue}');
      if (failure.expected != null) {
        print('   期望: ${failure.expected}');
      }
      if (failure.actual != null) {
        print('   实际: ${failure.actual}');
      }
      if (failure.suggestion != null) {
        print('   建议: ${failure.suggestion}');
      }
      print('');
    }

    print('═' * 80);
    print('');
    print('💡 请根据上述统计信息修复不一致项');
    print('   - 如果 YAML 过时，请更新 YAML');
    print('   - 如果代码错误，请修复代码');
    print('   - 如果不确定，请人工判断正确的源头');
    print('');
    print('═' * 80);
    print('');
  }
}

/// 测试失败信息
class TestFailure {
  final String testSuite;
  final String yamlFile;
  final String testName;
  final String issue;
  final String? expected;
  final String? actual;
  final String? suggestion;

  TestFailure({
    required this.testSuite,
    required this.yamlFile,
    required this.testName,
    required this.issue,
    this.expected,
    this.actual,
    this.suggestion,
  });
}

