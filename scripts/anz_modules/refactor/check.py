#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重构检查脚本 - 检查哪些文件和方法需要重构
根据 .cursor/rules/00-global.mdc 中的重构标准检查文件大小和方法长度
"""

import re
import sys
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass

_HERE = Path(__file__).resolve()
_CANDIDATES = list(_HERE.parents)
_FALLBACK = _HERE.parents[3] if len(_HERE.parents) >= 4 else _HERE.parent.parent
ROOT = next((p for p in _CANDIDATES if (p / 'pubspec.yaml').exists()), _FALLBACK)
LIB_DIR = ROOT / "lib"


@dataclass
class FileThreshold:
    """文件阈值配置"""
    max_lines: int  # 硬性阈值
    warning_lines: int  # 警告阈值
    file_type: str  # 文件类型描述


@dataclass
class MethodInfo:
    """方法信息"""
    name: str
    start_line: int
    end_line: int
    lines: int


def get_threshold(file_path: Path) -> Optional[FileThreshold]:
    """
    根据文件路径判断阈值配置
    返回 None 表示不需要检查（如 .g.dart 文件）
    """
    path_str = str(file_path.relative_to(ROOT))
    
    # 跳过生成的文件
    if path_str.endswith('.g.dart'):
        return None
    
    # 只检查 lib 下的 dart 文件
    if not path_str.startswith('lib/') or not path_str.endswith('.dart'):
        return None
    
    # 根据路径判断阈值
    if path_str.startswith('lib/presentation/'):
        return FileThreshold(max_lines=500, warning_lines=400, file_type="presentation")
    elif re.match(r'^lib/core/(utils|providers|services|monetization)/', path_str):
        return FileThreshold(max_lines=400, warning_lines=300, file_type="core")
    elif path_str.startswith('lib/data/repositories/'):
        return FileThreshold(max_lines=500, warning_lines=400, file_type="repository")
    elif path_str == 'lib/main.dart':
        return FileThreshold(max_lines=100, warning_lines=80, file_type="main")
    elif path_str.startswith('lib/data/models/'):
        return FileThreshold(max_lines=300, warning_lines=250, file_type="model")
    else:
        # 其他 lib 下的 dart 文件，使用默认阈值
        return FileThreshold(max_lines=400, warning_lines=300, file_type="default")


def remove_comments(content: str) -> str:
    """
    移除 Dart 代码中的注释
    支持单行注释 //、多行注释 /* */ 和文档注释 ///、/** */
    """
    result = []
    lines = content.split('\n')
    in_multiline_comment = False
    in_multiline_doc_comment = False
    
    for line in lines:
        i = 0
        in_string = False
        string_char = None
        new_line = []
        
        while i < len(line):
            char = line[i]
            peek = line[i:i+2]
            
            # 处理字符串
            if char in ('"', "'") and (i == 0 or line[i-1] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None
                new_line.append(char)
                i += 1
                continue
            
            # 在字符串内，直接添加字符
            if in_string:
                new_line.append(char)
                i += 1
                continue
            
            # 处理多行注释结束
            if in_multiline_comment or in_multiline_doc_comment:
                if peek == '*/':
                    in_multiline_comment = False
                    in_multiline_doc_comment = False
                    i += 2
                    continue
                i += 1
                continue
            
            # 处理单行注释 //
            if peek == '//' and (i + 2 >= len(line) or line[i+2] != '/'):
                # 这是单行注释，忽略该行剩余部分
                break
            
            # 处理文档注释 ///
            if line[i:i+3] == '///':
                # 这是文档注释，忽略该行剩余部分
                break
            
            # 处理多行注释开始 /* 或 /**
            if peek == '/*':
                if i + 2 < len(line) and line[i+2] == '*':
                    # 文档注释 /**
                    in_multiline_doc_comment = True
                    i += 3
                else:
                    # 普通多行注释 /*
                    in_multiline_comment = True
                    i += 2
                continue
            
            new_line.append(char)
            i += 1
        
        # 如果整行不是注释，添加到结果
        cleaned = ''.join(new_line).strip()
        if cleaned or in_multiline_comment or in_multiline_doc_comment:
            # 保留空行（但如果整行都是注释，则为空）
            result.append(''.join(new_line))
    
    return '\n'.join(result)


def count_lines(file_path: Path) -> int:
    """统计文件有效代码行数（排除注释和空行）"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 移除注释
        cleaned_content = remove_comments(content)
        
        # 统计非空行
        lines = cleaned_content.split('\n')
        code_lines = [line for line in lines if line.strip()]
        
        return len(code_lines)
    except Exception:
        return 0


def count_method_lines(content: str, start_line: int, end_line: int) -> int:
    """
    计算方法体的有效代码行数（排除注释和空行）
    start_line 和 end_line 都是基于原始内容的行号（从1开始）
    """
    lines = content.split('\n')
    if start_line < 1 or end_line > len(lines):
        return 0
    
    # 提取方法体内容
    method_lines = lines[start_line - 1:end_line]
    method_content = '\n'.join(method_lines)
    
    # 移除注释
    cleaned_content = remove_comments(method_content)
    
    # 统计非空行
    cleaned_lines = cleaned_content.split('\n')
    code_lines = [line for line in cleaned_lines if line.strip()]
    
    return len(code_lines)


def parse_methods(file_path: Path) -> List[MethodInfo]:
    """
    解析 Dart 文件，提取方法定义
    使用正则表达式匹配方法签名，然后计算方法体行数（排除注释和空行）
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
    except Exception:
        return []
    
    methods = []
    # 匹配方法定义：包括普通方法、getter、setter、构造函数等
    # 匹配模式: [修饰符] [返回类型] methodName(参数) { 或 =>
    method_patterns = [
        # 匹配 getter: get methodName { 或 =>
        re.compile(r'^\s*(?:@\w+\s+)*(?:external\s+)?(?:static\s+)?(?:async\s+)?(?:Future<.*?>\s+)?(?:[\w<>?\[\]]+\s+)?get\s+(\w+)\s*(?:=>|{|;)', re.MULTILINE),
        # 匹配 setter: set methodName(参数) { 或 =>
        re.compile(r'^\s*(?:@\w+\s+)*(?:external\s+)?(?:static\s+)?(?:async\s+)?(?:Future<.*?>\s+)?(?:[\w<>?\[\]]+\s+)?set\s+(\w+)\s*\([^)]*\)\s*(?:=>|{|;)', re.MULTILINE),
        # 匹配普通方法和构造函数: methodName(参数) { 或 =>
        re.compile(r'^\s*(?:@\w+\s+)*(?:external\s+)?(?:static\s+)?(?:async\s+)?(?:Future<.*?>\s+)?(?:[\w<>?\[\]]+\s+)?(\w+)\s*\([^)]*\)\s*(?:=>|{|;)', re.MULTILINE),
    ]
    
    found_methods = {}  # 用于去重
    
    for pattern in method_patterns:
        for match in pattern.finditer(content):
            method_name = match.group(1)
            # 跳过一些常见的关键字
            if method_name in ('if', 'while', 'for', 'switch', 'catch', 'try', 'when', 'return', 'class', 'enum', 'extension', 'mixin', 'typedef'):
                continue
            
            start_pos = match.start()
            start_line = content[:start_pos].count('\n') + 1
            
            # 如果已找到同名方法，跳过（避免重复）
            if (method_name, start_line) in found_methods:
                continue
            
            # 找到方法体开始位置
            body_start = match.end()
            
            # 检查是否是 => 形式
            arrow_pos = content.find('=>', match.end() - 2, match.end() + 10)
            if arrow_pos != -1 and arrow_pos < match.end() + 10:
                # => 形式，找到分号或换行结束
                i = arrow_pos + 2
                while i < len(content):
                    if content[i] == '\n':
                        break
                    if content[i] == ';':
                        i += 1
                        break
                    i += 1
                end_line = content[:i].count('\n') + 1
            else:
                # { } 形式，需要匹配大括号
                brace_count = 0
                in_string = False
                string_char = None
                i = body_start
                
                # 找到第一个 {
                while i < len(content):
                    if content[i] in ('"', "'") and (i == 0 or content[i-1] != '\\'):
                        in_string = not in_string
                        if in_string:
                            string_char = content[i]
                        else:
                            string_char = None
                    elif not in_string:
                        if content[i] == '{':
                            brace_count = 1
                            i += 1
                            break
                    i += 1
                
                # 匹配所有大括号
                while i < len(content) and brace_count > 0:
                    if content[i] in ('"', "'") and (i == 0 or content[i-1] != '\\'):
                        in_string = not in_string
                        if in_string:
                            string_char = content[i]
                        else:
                            string_char = None
                    elif not in_string:
                        if content[i] == '{':
                            brace_count += 1
                        elif content[i] == '}':
                            brace_count -= 1
                    i += 1
                
                end_line = content[:i].count('\n') + 1
            
            # 计算方法的有效代码行数（排除注释和空行）
            method_lines = count_method_lines(content, start_line, end_line)
            
            found_methods[(method_name, start_line)] = True
            methods.append(MethodInfo(
                name=method_name,
                start_line=start_line,
                end_line=end_line,
                lines=method_lines
            ))
    
    return methods


def find_dart_files() -> List[Path]:
    """查找所有需要检查的 Dart 文件"""
    if not LIB_DIR.exists():
        return []
    
    dart_files = []
    for file_path in LIB_DIR.rglob("*.dart"):
        # 跳过生成的文件
        if file_path.name.endswith('.g.dart'):
            continue
        dart_files.append(file_path)
    
    return sorted(dart_files)


def main():
    """主函数"""
    print("🔍 正在扫描 lib/ 目录下的 Dart 文件...\n")
    print("📊 行数统计已排除注释和空行\n")
    
    dart_files = find_dart_files()
    if not dart_files:
        print("❌ 未找到任何 Dart 文件")
        sys.exit(1)
    
    has_refactor_needed = False
    files_with_issues = []
    
    for file_path in dart_files:
        threshold = get_threshold(file_path)
        if threshold is None:
            continue
        
        file_lines = count_lines(file_path)
        relative_path = str(file_path.relative_to(ROOT))
        
        # 检查文件是否需要重构
        file_needs_refactor = file_lines > threshold.warning_lines
        
        # 检查方法是否需要重构
        methods = parse_methods(file_path)
        long_methods = [m for m in methods if m.lines > 50]  # 警告阈值 50 行
        
        if file_needs_refactor or long_methods:
            has_refactor_needed = True
            files_with_issues.append({
                'path': relative_path,
                'lines': file_lines,
                'threshold': threshold,
                'needs_refactor': file_needs_refactor,
                'long_methods': long_methods
            })
    
    # 输出结果
    if not has_refactor_needed:
        print("✅ 所有文件和方法都符合重构标准！")
        sys.exit(0)
    
    # 输出需要优化的文件和函数
    print("⚠️  以下文件和函数需要优化：\n")
    
    for file_info in files_with_issues:
        relative_path = file_info['path']
        file_lines = file_info['lines']
        threshold = file_info['threshold']
        file_needs_refactor = file_info['needs_refactor']
        long_methods = file_info['long_methods']
        
        # 输出文件信息
        status = "❌" if file_needs_refactor else "⚠️"
        print(f"{status} {relative_path}")
        print(f"   代码行数: {file_lines} (警告阈值: {threshold.warning_lines}, 最大: {threshold.max_lines})")
        
        # 输出需要优化的函数
        if long_methods:
            print(f"   需要优化的函数:")
            for method in long_methods:
                print(f"     - {method.name}() (第 {method.start_line}-{method.end_line} 行, {method.lines} 行代码)")
        print()
    
    sys.exit(1)


if __name__ == '__main__':
    main()

