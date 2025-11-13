import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/rich_text_description_preview.dart';
import 'package:granoflow/core/utils/delta_json_utils.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  group('RichTextDescriptionPreview', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    group('空状态', () {
      testWidgets('description 为 null 时显示"添加描述"按钮（readOnly 为 false）', (tester) async {
        bool tapped = false;
        
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: null,
              readOnly: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证显示"添加描述"按钮
        expect(find.text('添加描述'), findsOneWidget);
        expect(find.byIcon(Icons.notes_outlined), findsOneWidget);
        
        // 点击按钮
        await tester.tap(find.text('添加描述'));
        await tester.pumpAndSettle();
        
        expect(tapped, isTrue);
      });

      testWidgets('description 为 null 时不显示内容（readOnly 为 true）', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: null,
              readOnly: true,
              onTap: null,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证不显示任何内容
        expect(find.text('添加描述'), findsNothing);
        expect(find.byType(RichTextDescriptionPreview), findsOneWidget);
      });
    });

    group('有内容状态', () {
      testWidgets('有效的 Delta JSON 正确显示预览', (tester) async {
        final document = Document()..insert(0, 'Test description\n');
        final deltaJson = DeltaJsonUtils.documentToJson(document);
        
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: deltaJson,
              readOnly: false,
              onTap: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证预览显示（QuillEditor 应该存在）
        expect(find.byType(RichTextDescriptionPreview), findsOneWidget);
      });

      testWidgets('点击预览区域触发 onTap 回调（readOnly 为 false）', (tester) async {
        bool tapped = false;
        final document = Document()..insert(0, 'Test\n');
        final deltaJson = DeltaJsonUtils.documentToJson(document);
        
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: deltaJson,
              readOnly: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 点击预览区域
        await tester.tap(find.byType(RichTextDescriptionPreview));
        await tester.pumpAndSettle();
        
        expect(tapped, isTrue);
      });

      testWidgets('预览区域不可点击（readOnly 为 true）', (tester) async {
        bool tapped = false;
        final document = Document()..insert(0, 'Test\n');
        final deltaJson = DeltaJsonUtils.documentToJson(document);
        
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: deltaJson,
              readOnly: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 尝试点击预览区域（应该无效）
        await tester.tap(find.byType(RichTextDescriptionPreview));
        await tester.pumpAndSettle();
        
        expect(tapped, isFalse);
      });
    });

    group('错误处理', () {
      testWidgets('无效的 Delta JSON 显示"添加描述"按钮（老数据废弃）', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: 'invalid json',
              readOnly: false,
              onTap: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证显示"添加描述"按钮（老数据废弃）
        expect(find.text('添加描述'), findsOneWidget);
      });

      testWidgets('旧格式的纯文本显示"添加描述"按钮（老数据废弃）', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            RichTextDescriptionPreview(
              description: 'Hello World',
              readOnly: false,
              onTap: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证显示"添加描述"按钮（老数据废弃）
        expect(find.text('添加描述'), findsOneWidget);
      });
    });
  });
}

