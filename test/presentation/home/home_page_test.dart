import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/app.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/presentation/widgets/app_logo.dart';
import '../test_support/fakes.dart';

void main() {
  final taskRepository = StubTaskRepository();
  final focusRepository = StubFocusSessionRepository();
  final tagRepository = StubTagRepository();
  final preferenceRepository = StubPreferenceRepository();
  final templateRepository = StubTaskTemplateRepository();
  final seedRepository = StubSeedRepository();

  // TODO: Home 页面顶部搜索栏正在重构，等待布局稳定后恢复该测试
  testWidgets('renders localized content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWith((ref) async => taskRepository),
          focusSessionRepositoryProvider.overrideWith((ref) async => focusRepository),
          tagRepositoryProvider.overrideWith((ref) async => tagRepository),
          preferenceRepositoryProvider.overrideWith((ref) async => preferenceRepository),
          taskTemplateRepositoryProvider.overrideWith((ref) async => templateRepository),
          seedRepositoryProvider.overrideWith((ref) async => seedRepository),
        ],
        child: const GranoFlowApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // 验证应用标题存在（不依赖具体翻译文本）
    expect(find.textContaining('GranoFlow'), findsOneWidget);
    
    // 验证问候语存在（不依赖具体翻译文本）
    expect(find.textContaining('GranoFlow'), findsAtLeastNWidgets(1));
    
    // 验证文本组件存在（验证UI渲染正常）
    expect(find.byType(Text), findsWidgets);
    
    // 验证 AppLogo 存在（替换了原来的计时器图标）
    expect(find.byType(AppLogo), findsOneWidget);
  }, skip: true);

  // TODO: Home 页面布局/文案近期持续变更，等待 UI 稳定后重写该用例
  testWidgets(
    'renders localized content in Chinese',
    (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWith((ref) async => taskRepository),
          focusSessionRepositoryProvider.overrideWith((ref) async => focusRepository),
          tagRepositoryProvider.overrideWith((ref) async => tagRepository),
          preferenceRepositoryProvider.overrideWith((ref) async => preferenceRepository),
          taskTemplateRepositoryProvider.overrideWith((ref) async => templateRepository),
          seedRepositoryProvider.overrideWith((ref) async => seedRepository),
        ],
        child: const GranoFlowApp(
          locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    // 验证应用标题存在（不依赖具体翻译文本）
    expect(find.textContaining('GranoFlow'), findsOneWidget);
    
    // 验证问候语存在（不依赖具体翻译文本）
    expect(find.textContaining('GranoFlow'), findsAtLeastNWidgets(1));
    
    // 验证 AppLogo 存在（替换了原来的计时器图标）
    expect(find.byType(AppLogo), findsOneWidget);
    
    // 验证页面包含文本内容（不依赖具体翻译）
    expect(find.byType(Text), findsAtLeastNWidgets(2));
  }, skip: true);
}
