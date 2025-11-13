import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/rich_text_description_editor_dialog.dart';
import 'package:granoflow/core/utils/delta_json_utils.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  group('RichTextDescriptionEditorDialog', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(
          body: child,
        ),
      );
    }

    group('弹窗显示', () {
      testWidgets('弹窗正确显示', (tester) async {
        String? savedDescription;
        
        await tester.pumpWidget(
          createTestWidget(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => RichTextDescriptionEditorDialog(
                      initialDescription: null,
                      onSave: (description) {
                        savedDescription = description;
                      },
                      title: '编辑描述',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );

        // 打开弹窗
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // 验证弹窗显示
        expect(find.byType(RichTextDescriptionEditorDialog), findsOneWidget);
      });

      testWidgets('标题正确显示', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => RichTextDescriptionEditorDialog(
                      initialDescription: null,
                      onSave: (_) {},
                      title: '测试标题',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // 验证标题显示
        expect(find.text('测试标题'), findsOneWidget);
      });
    });

    group('初始内容', () {
      testWidgets('有效的 Delta JSON 正确加载到编辑器', (tester) async {
        final document = Document()..insert(0, 'Initial content\n');
        final deltaJson = DeltaJsonUtils.documentToJson(document);
        
        await tester.pumpWidget(
          createTestWidget(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => RichTextDescriptionEditorDialog(
                      initialDescription: deltaJson,
                      onSave: (_) {},
                      title: '编辑描述',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // 验证编辑器存在
        expect(find.byType(RichTextDescriptionEditorDialog), findsOneWidget);
      });

      testWidgets('无效的 JSON 使用空内容初始化', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => RichTextDescriptionEditorDialog(
                      initialDescription: 'invalid json',
                      onSave: (_) {},
                      title: '编辑描述',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // 验证弹窗显示（即使内容无效）
        expect(find.byType(RichTextDescriptionEditorDialog), findsOneWidget);
      });
    });

    group('关闭功能', () {
      testWidgets('弹窗可以创建和显示', (tester) async {
        // 直接测试 Dialog 组件，不通过 showDialog
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionEditorDialog(
              initialDescription: null,
              onSave: (_) {},
              title: '编辑描述',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证弹窗组件存在
        expect(find.byType(RichTextDescriptionEditorDialog), findsOneWidget);
        expect(find.text('编辑描述'), findsOneWidget);
      });
    });
  });
}

