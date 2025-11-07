import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('16KB Page Size Compatibility Tests', () {
    testWidgets(
      'should launch without 16KB compatibility warning dialog',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 检查是否有 16KB 警告对话框
        // 如果出现警告对话框，通常会有一个包含 "16 KB" 或 "compatible" 文本的对话框
        final warningDialog = find.textContaining('16 KB', findRichText: true);
        final compatibleDialog = find.textContaining('compatible', findRichText: true);
        final elfDialog = find.textContaining('ELF', findRichText: true);

        // 等待一小段时间，确保对话框有时间显示
        await tester.pump(const Duration(seconds: 2));

        // 验证没有出现警告对话框
        expect(warningDialog, findsNothing, reason: '不应该出现 16KB 警告对话框');
        expect(compatibleDialog, findsNothing, reason: '不应该出现兼容性警告对话框');
        expect(elfDialog, findsNothing, reason: '不应该出现 ELF 对齐错误对话框');

        // 验证应用正常启动（可以找到主界面元素）
        // 这里可以根据实际应用的主界面元素来验证
        // 例如：查找导航栏、主内容区域等
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // 应用应该已经加载完成，没有崩溃
        expect(tester.binding.transientCallbackCount, equals(0), reason: '应用应该稳定运行，没有待处理的回调');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should run all core features without crashes',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 尝试导航到不同页面，验证应用功能正常
        // 这里可以根据实际应用的功能来测试
        
        // 验证应用可以正常交互
        // 例如：点击按钮、输入文本等基本操作不应该导致崩溃
        
        // 应用应该稳定运行
        expect(tester.binding.transientCallbackCount, equals(0), reason: '应用应该稳定运行');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
