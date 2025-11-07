import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/timer_persistence_service.dart';

void main() {
  // 注意：SharedPreferences 在单元测试中需要平台支持
  // 这些测试需要在集成测试中运行，或者使用 mock
  // 这里先跳过，实际测试在集成测试中完成
  group('TimerPersistenceService', () {
    test('service can be instantiated', () {
      final service = TimerPersistenceService();
      expect(service, isNotNull);
    });

    // TODO: 添加 mock SharedPreferences 的测试
    // 或者将这些测试移到集成测试中
  });
}

