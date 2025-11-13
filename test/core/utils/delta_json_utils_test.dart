import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/utils/delta_json_utils.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  group('DeltaJsonUtils', () {
    group('parseDeltaJson', () {
      test('null 输入返回 null', () {
        final result = DeltaJsonUtils.parseDeltaJson(null);
        expect(result, isNull);
      });

      test('空字符串返回 null', () {
        final result = DeltaJsonUtils.parseDeltaJson('');
        expect(result, isNull);
      });

      test('有效的 Delta JSON 解析成功', () {
        // 创建一个简单的 Delta JSON
        final document = Document()..insert(0, 'Hello\n');
        final deltaJson = DeltaJsonUtils.documentToJson(document);
        
        final result = DeltaJsonUtils.parseDeltaJson(deltaJson);
        expect(result, isNotNull);
      });

      test('无效的 JSON 返回 null（不抛出异常）', () {
        final result = DeltaJsonUtils.parseDeltaJson('invalid json');
        expect(result, isNull);
      });

      test('旧格式的纯文本返回 null（不进行转换）', () {
        final result = DeltaJsonUtils.parseDeltaJson('Hello World');
        expect(result, isNull);
      });
    });

    group('deltaToJson', () {
      test('Delta 对象正确序列化为 JSON 字符串', () {
        final document = Document()..insert(0, 'Test\n');
        final delta = document.toDelta();
        final json = DeltaJsonUtils.deltaToJson(delta);
        
        expect(json, isA<String>());
        expect(json.isNotEmpty, isTrue);
      });
    });

    group('documentToJson', () {
      test('Document 对象正确序列化为 JSON 字符串', () {
        final document = Document()..insert(0, 'Test\n');
        final json = DeltaJsonUtils.documentToJson(document);
        
        expect(json, isA<String>());
        expect(json.isNotEmpty, isTrue);
      });
    });

    group('jsonToDocument', () {
      test('有效的 Delta JSON 正确解析为 Document', () {
        final document = Document()..insert(0, 'Hello\n');
        final json = DeltaJsonUtils.documentToJson(document);
        
        final result = DeltaJsonUtils.jsonToDocument(json);
        expect(result, isA<Document>());
        // 验证内容正确（Document 可能包含额外的换行符）
        expect(result.toPlainText().trim(), 'Hello');
      });

      test('无效的 JSON 返回空 Document', () {
        final result = DeltaJsonUtils.jsonToDocument('invalid');
        expect(result, isA<Document>());
        // 空 Document 的 toPlainText() 可能返回 '\n'，所以检查长度 <= 1
        expect(result.toPlainText().trim(), isEmpty);
      });

      test('null 输入返回空 Document', () {
        final result = DeltaJsonUtils.jsonToDocument(null);
        expect(result, isA<Document>());
        // 空 Document 的 toPlainText() 可能返回 '\n'，所以检查长度 <= 1
        expect(result.toPlainText().trim(), isEmpty);
      });

      test('空字符串返回空 Document', () {
        final result = DeltaJsonUtils.jsonToDocument('');
        expect(result, isA<Document>());
        // 空 Document 的 toPlainText() 可能返回 '\n'，所以检查长度 <= 1
        expect(result.toPlainText().trim(), isEmpty);
      });
    });

    group('isValidDeltaJson', () {
      test('有效的 Delta JSON 返回 true', () {
        final document = Document()..insert(0, 'Test\n');
        final json = DeltaJsonUtils.documentToJson(document);
        
        final result = DeltaJsonUtils.isValidDeltaJson(json);
        expect(result, isTrue);
      });

      test('无效的 JSON 返回 false', () {
        final result = DeltaJsonUtils.isValidDeltaJson('invalid');
        expect(result, isFalse);
      });

      test('null 输入返回 false', () {
        final result = DeltaJsonUtils.isValidDeltaJson(null);
        expect(result, isFalse);
      });

      test('空字符串返回 false', () {
        final result = DeltaJsonUtils.isValidDeltaJson('');
        expect(result, isFalse);
      });

      test('旧格式的纯文本返回 false', () {
        final result = DeltaJsonUtils.isValidDeltaJson('Hello World');
        expect(result, isFalse);
      });
    });
  });
}

