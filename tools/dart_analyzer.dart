import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run dart_analyzer.dart <file_path>');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    stderr.writeln('File not found: $filePath');
    exit(1);
  }

  try {
    // 规范化为绝对路径
    final absolutePath = path.normalize(file.absolute.path);
    final analysis = await analyzeDartFile(absolutePath);
    print(jsonEncode(analysis));
  } catch (e, stackTrace) {
    stderr.writeln('Analysis error: $e');
    stderr.writeln(stackTrace);
    exit(1);
  }
}

Future<Map<String, dynamic>> analyzeDartFile(String filePath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [path.dirname(filePath)],
  );

  final context = collection.contextFor(filePath);
  final session = context.currentSession;
  final result = await session.getResolvedUnit(filePath);

  if (result is! ResolvedUnitResult) {
    throw Exception('Failed to analyze file');
  }

  final visitor = DartFileVisitor(filePath);
  result.unit.accept(visitor);

  return visitor.toJson();
}

class DartFileVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  String? className;
  String? classType;
  String? extendsClause;
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> methods = [];
  List<String> imports = [];
  Set<String> calls = {};
  Set<String> i18nKeys = {};
  Set<String> designTokens = {};

  DartFileVisitor(this.filePath);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    className = node.name.lexeme;

    // 判断类型
    final extendsClauseNode = node.extendsClause;
    if (extendsClauseNode != null) {
      final superclass = extendsClauseNode.superclass.name2.lexeme;
      extendsClause = superclass;
      
      if (superclass.contains('Stateless')) {
        classType = 'StatelessWidget';
      } else if (superclass.contains('Stateful')) {
        classType = 'StatefulWidget';
      } else if (superclass.contains('Consumer')) {
        classType = 'ConsumerWidget';
      }
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var variable in node.fields.variables) {
      final type = node.fields.type?.toSource() ?? 'dynamic';
      final name = variable.name.lexeme;
      final hasDefault = variable.initializer != null;
      final defaultValue = variable.initializer?.toSource();

      // 提取文档注释
      String? docComment;
      if (node.documentationComment != null) {
        docComment = node.documentationComment!.tokens
            .map((t) => t.lexeme)
            .join('\n');
      }

      properties.add({
        'name': name,
        'type': type.replaceAll('?', ''),
        'is_required': !type.contains('?') && !hasDefault,
        'is_final': node.fields.isFinal,
        'has_default': hasDefault,
        'default_value': defaultValue,
        'doc_comment': docComment,
      });
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final parameters = <Map<String, dynamic>>[];
    if (node.parameters != null) {
      for (var param in node.parameters!.parameters) {
        if (param is SimpleFormalParameter) {
          parameters.add({
            'name': param.name?.lexeme ?? '',
            'type': param.type?.toSource() ?? 'dynamic',
            'is_required': param.isRequired,
          });
        } else if (param is DefaultFormalParameter) {
          parameters.add({
            'name': param.parameter.name?.lexeme ?? '',
            'type': param.parameter is SimpleFormalParameter
                ? (param.parameter as SimpleFormalParameter).type?.toSource() ??
                    'dynamic'
                : 'dynamic',
            'is_required': param.isRequired,
            'has_default': param.defaultValue != null,
          });
        }
      }
    }

    methods.add({
      'name': node.name.lexeme,
      'return_type': node.returnType?.toSource() ?? 'void',
      'is_override': _hasOverrideAnnotation(node),
      'is_async': node.body.isAsynchronous,
      'parameters': parameters,
    });
    super.visitMethodDeclaration(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    imports.add(uri);

    // 提取项目内部调用：只收集本项目的文件，排除 Flutter SDK 和第三方包
    if (uri.startsWith('package:')) {
      // 只收集 package:granoflow/... 的导入（项目内部）
      // 排除 package:flutter/..., package:riverpod/..., package:isar/... 等第三方包
      if (uri.startsWith('package:granoflow/')) {
        final parts = uri.split('/');
        if (parts.length > 1) {
          // package:granoflow/xxx -> lib/xxx
          final relativePath = 'lib/${parts.sublist(1).join('/')}';
          calls.add(relativePath);
        }
      }
      // 其他 package: 开头的都是外部依赖，不记录
    } else if (uri.startsWith('../') || uri.startsWith('./')) {
      // 相对导入：项目内部文件
      calls.add(uri);
    }
    // dart:xxx 也是外部依赖，不记录

    super.visitImportDirective(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // 检测 i18n 键：l10n.someKey 模式
    final target = node.target?.toString() ?? '';
    final methodName = node.methodName.name;
    
    // 只有当 target 明确是 l10n 变量时，才提取方法名作为 i18n 键
    // 排除 AppLocalizations.of(context) 这种获取实例的调用
    if (target == 'l10n' || target.endsWith('.l10n')) {
      // 排除常见的非 i18n 方法
      final excludedMethods = {'of', 'watch', 'read', 'toString', 'hashCode', 'runtimeType'};
      if (!excludedMethods.contains(methodName)) {
        i18nKeys.add(methodName);
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // 检测设计令牌：OceanBreezeColorSchemes.someColor
    if (node.prefix.name == 'OceanBreezeColorSchemes') {
      designTokens.add('${node.prefix.name}.${node.identifier.name}');
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // 检测通过属性访问的设计令牌
    final target = node.target?.toString() ?? '';
    if (target.contains('OceanBreezeColorSchemes')) {
      designTokens.add('OceanBreezeColorSchemes.${node.propertyName.name}');
    }

    super.visitPropertyAccess(node);
  }

  bool _hasOverrideAnnotation(MethodDeclaration node) {
    return node.metadata.any((m) => m.name.name == 'override');
  }

  String _determinePattern() {
    if (classType?.contains('Stateless') == true) return 'stateless';
    if (classType?.contains('Stateful') == true) return 'stateful';
    if (classType?.contains('Consumer') == true) return 'consumer';
    return 'unknown';
  }

  Map<String, dynamic> toJson() {
    return {
      'file_path': filePath,
      'class_name': className,
      'class_type': classType,
      'extends_clause': extendsClause,
      'pattern': _determinePattern(),
      'properties': properties,
      'methods': methods,
      'imports': imports,
      'calls': calls.toList(),
      'i18n_keys': i18nKeys.toList(),
      'design_tokens': designTokens.toList(),
    };
  }
}

