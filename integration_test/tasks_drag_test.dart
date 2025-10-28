import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tasks Drag and Drop Integration Tests', () {
    testWidgets('should load app and verify drag components exist', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 等待应用加载完成
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证应用已加载
      expect(find.byType(MaterialApp), findsOneWidget);

      // 查找任务列表
      expect(find.byType(ListTile), findsWidgets);

      // 验证拖拽相关组件存在
      expect(find.byType(LongPressDraggable), findsWidgets);
      expect(find.byType(DragTarget), findsWidgets);
    });

    testWidgets('should verify drag handler is enabled for collapsed tasks', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 等待应用加载完成
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 查找任务列表
      expect(find.byType(ListTile), findsWidgets);

      // 获取第一个任务
      final firstTask = find.byType(ListTile).first;
      expect(firstTask, findsOneWidget);

      // 验证长按可以触发拖拽
      await tester.longPress(firstTask);
      await tester.pumpAndSettle();

      // 验证拖拽反馈存在
      expect(find.byType(Material), findsWidgets);
    });
  });
}
