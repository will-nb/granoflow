#!/usr/bin/env python3
"""
Dart 文件分析器：自动生成 architecture YAML 文档

分析 Dart 文件并提取：
- 类名、方法、属性
- 导入依赖
- i18n 键
- 设计令牌
- 生成符合模板规范的 YAML 文档

策略：
1. 优先使用 tools/dart_analyzer.dart 进行精确 AST 分析
2. 降级到正则表达式分析（如果 Dart 分析器不可用）
3. 支持合并模式，保留人工维护的字段
"""
import sys
import re
import yaml
import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Set, Optional

ROOT = Path(__file__).resolve().parents[1]


def call_dart_analyzer(dart_file: Path) -> Optional[Dict]:
    """调用 Dart 分析器获取精确信息"""
    tools_dir = ROOT / 'tools'
    analyzer = tools_dir / 'dart_analyzer.dart'
    
    if not analyzer.exists():
        # 降级到正则表达式分析
        return None
    
    try:
        result = subprocess.run(
            ['dart', 'run', str(analyzer), str(dart_file.absolute())],
            cwd=str(tools_dir),
            capture_output=True,
            text=True,
            timeout=60  # 增加到 60 秒，适应并发环境
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            print(f"[yaml_generator] Dart 分析器警告: {result.stderr}", file=sys.stderr)
            return None
    except subprocess.TimeoutExpired:
        print(f"[yaml_generator] Dart 分析器超时", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"[yaml_generator] Dart 分析器输出解析失败: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"[yaml_generator] Dart 分析器失败: {e}", file=sys.stderr)
        return None


def _extract_doc_text(doc_comment: Optional[str]) -> str:
    """清理文档注释"""
    if not doc_comment:
        return ""
    # 移除 /// 和 /** */ 标记
    lines = doc_comment.split('\n')
    cleaned = []
    for line in lines:
        line = line.strip()
        if line.startswith('///'):
            cleaned.append(line[3:].strip())
        elif line.startswith('/**') or line.startswith('*/'):
            continue
        elif line.startswith('*'):
            cleaned.append(line[1:].strip())
        else:
            cleaned.append(line)
    return ' '.join(cleaned).strip()


def merge_yaml_data(existing: Dict, new_data: Dict, auto_fields: List[str]) -> Dict:
    """合并 YAML 数据，保留人工维护的字段
    
    Args:
        existing: 现有的 YAML 数据
        new_data: 新生成的数据
        auto_fields: 可自动更新的字段列表（如 properties, i18n_keys 等）
    
    Returns:
        合并后的数据
    """
    result = existing.copy()
    
    # 更新 meta 中的部分字段
    if 'meta' in new_data:
        if 'meta' not in result:
            result['meta'] = {}
        result['meta']['last_updated'] = new_data['meta'].get('last_updated')
        result['meta']['file_path'] = new_data['meta'].get('file_path')
        # name 只在为空时更新
        if not result['meta'].get('name'):
            result['meta']['name'] = new_data['meta'].get('name')
    
    # 更新可自动生成的字段
    for field in auto_fields:
        if field in new_data:
            result[field] = new_data[field]
    
    return result


class DartAnalyzer:
    def __init__(self, dart_file: Path):
        self.dart_file = dart_file
        self.content = dart_file.read_text(encoding='utf-8')
        self.lines = self.content.split('\n')
        
    def extract_class_name(self) -> Optional[str]:
        """提取主类名"""
        # 匹配 class ClassName extends/implements/with
        pattern = r'class\s+(\w+)\s+(?:extends|implements|with|\{)'
        match = re.search(pattern, self.content)
        return match.group(1) if match else None
    
    def extract_widget_type(self) -> str:
        """提取 Widget 类型"""
        if 'StatelessWidget' in self.content:
            return 'stateless'
        elif 'StatefulWidget' in self.content or 'ConsumerStatefulWidget' in self.content:
            return 'stateful'
        elif 'ConsumerWidget' in self.content:
            return 'consumer'
        return 'stateless'
    
    def extract_imports(self) -> List[str]:
        """提取导入语句"""
        imports = []
        for line in self.lines:
            if line.strip().startswith('import '):
                # 提取导入路径
                match = re.search(r"import\s+['\"](.+?)['\"]", line)
                if match:
                    imports.append(match.group(1))
        return imports
    
    def extract_calls(self) -> List[str]:
        """分析调用的其他组件"""
        calls = set()
        imports = self.extract_imports()
        
        # 从项目内部导入中提取可能的调用
        for imp in imports:
            if imp.startswith('package:') and 'granoflow' not in imp:
                continue  # 跳过外部包
            if imp.startswith('../') or imp.startswith('../../'):
                # 相对导入，提取文件路径
                calls.add(self._normalize_import_path(imp))
        
        return sorted(list(calls))
    
    def extract_i18n_keys(self) -> List[str]:
        """提取本地化键"""
        keys = set()
        # 匹配 AppLocalizations.of(context).xxx 或 AppLocalizations.xxx
        pattern = r'AppLocalizations\.(?:of\([^)]+\)\.)?(\w+)'
        for match in re.finditer(pattern, self.content):
            keys.add(match.group(1))
        return sorted(list(keys))
    
    def extract_design_tokens(self) -> List[str]:
        """提取设计令牌"""
        tokens = set()
        # 匹配 OceanBreezeColorSchemes.xxx
        pattern = r'OceanBreezeColorSchemes\.(\w+)'
        for match in re.finditer(pattern, self.content):
            tokens.add(f'OceanBreezeColorSchemes.{match.group(1)}')
        return sorted(list(tokens))
    
    def extract_properties(self) -> List[Dict]:
        """提取类属性（从 constructor 和 final 字段）"""
        properties = []
        seen = set()
        
        # 方法1: 从 final 字段提取
        pattern = r'///\s*([^\n]+)\n\s*final\s+(\w+\??)\s+(\w+);'
        for match in re.finditer(pattern, self.content):
            comment = match.group(1).strip()
            prop_type = match.group(2)
            prop_name = match.group(3)
            if prop_name in seen:
                continue
            seen.add(prop_name)
            required = '?' not in prop_type
            properties.append({
                'name': prop_name,
                'type': prop_type.replace('?', ''),
                'required': required,
                'description': comment,
                'default_value': None,
            })
        
        # 方法2: 如果没有注释，尝试不带注释的匹配
        if not properties:
            pattern = r'final\s+(\w+\??)\s+(\w+);'
            for match in re.finditer(pattern, self.content):
                prop_type = match.group(1)
                prop_name = match.group(2)
                if prop_name in seen:
                    continue
                seen.add(prop_name)
                required = '?' not in prop_type
                properties.append({
                    'name': prop_name,
                    'type': prop_type.replace('?', ''),
                    'required': required,
                    'description': f'{prop_name} 属性',
                    'default_value': None,
                })
        
        return properties
    
    def extract_methods(self) -> List[Dict]:
        """提取方法"""
        methods = []
        # 匹配方法定义
        pattern = r'(\w+)\s+(\w+)\([^)]*\)\s*(?:async)?\s*\{'
        for match in re.finditer(pattern, self.content):
            return_type = match.group(1)
            method_name = match.group(2)
            if method_name in ['build', 'initState', 'dispose', 'createState']:
                continue  # 跳过生命周期方法，稍后单独处理
            methods.append({
                'name': method_name,
                'return_type': return_type,
                'description': f'{method_name} 方法',
            })
        return methods
    
    def _normalize_import_path(self, imp: str) -> str:
        """规范化导入路径，将相对路径转换为项目相对路径"""
        from pathlib import Path
        import os
        
        # 如果已经是 lib/ 开头的路径，直接返回
        if imp.startswith('lib/'):
            return imp
        
        # 如果是 package: 导入，转换为 lib/ 路径
        if imp.startswith('package:'):
            parts = imp.split('/')
            if len(parts) > 1:
                # package:granoflow/xxx -> lib/xxx
                return 'lib/' + '/'.join(parts[1:])
            return imp
        
        # 处理相对路径：../ 或 ./
        if imp.startswith('../') or imp.startswith('./'):
            # 获取当前文件所在目录
            current_dir = self.dart_file.parent
            # 解析相对路径
            target_path = (current_dir / imp).resolve()
            # 转换为相对于项目根的路径
            try:
                rel_path = target_path.relative_to(ROOT)
                return str(rel_path)
            except ValueError:
                # 如果无法转换为相对路径，返回原值
                return imp
        
        # 其他情况，假设是 lib/ 下的文件
        return f'lib/{imp}' if not imp.startswith('lib/') else imp
    
    def get_relative_path(self) -> str:
        """获取相对于项目根的路径"""
        try:
            return str(self.dart_file.relative_to(ROOT))
        except ValueError:
            return str(self.dart_file)


def generate_widget_yaml(dart_file: Path, analyzer: DartAnalyzer, template_path: Path, dart_data: Optional[Dict] = None) -> Dict:
    """生成 Widget YAML
    
    Args:
        dart_file: Dart 文件路径
        analyzer: 正则表达式分析器（降级使用）
        template_path: 模板路径
        dart_data: Dart AST 分析器数据（优先使用）
    """
    # 加载模板
    with template_path.open('r', encoding='utf-8') as f:
        doc = yaml.safe_load(f)
    
    # 优先使用 Dart 分析器数据
    if dart_data:
        class_name = dart_data.get('class_name', 'UnknownWidget')
        widget_type = dart_data.get('pattern', 'stateless')
        print(f'[yaml_generator] 使用 Dart AST 分析结果', file=sys.stderr)
    else:
        class_name = analyzer.extract_class_name() or 'UnknownWidget'
        widget_type = analyzer.extract_widget_type()
        print(f'[yaml_generator] 降级使用正则表达式分析', file=sys.stderr)
    
    # 填充 meta
    doc['meta']['name'] = class_name
    doc['meta']['file_path'] = analyzer.get_relative_path()
    doc['meta']['description'] = f'{class_name} 组件'
    doc['meta']['created_date'] = datetime.now().strftime('%y%m%d')
    doc['meta']['last_updated'] = datetime.now().strftime('%y%m%d')
    
    # 填充 widget_definition
    if 'widget_definition' not in doc:
        doc['widget_definition'] = {}
    doc['widget_definition']['name'] = class_name
    doc['widget_definition']['pattern'] = widget_type
    # 清理 category 占位符，只保留第一个选项
    if 'category' in doc['widget_definition'] and '|' in str(doc['widget_definition']['category']):
        doc['widget_definition']['category'] = 'ui_component'
    # 清理 reusable 占位符
    if 'reusable' in doc['widget_definition'] and '|' in str(doc['widget_definition']['reusable']):
        doc['widget_definition']['reusable'] = True
    
    # 填充 source_of_truth
    doc['source_of_truth'] = analyzer.get_relative_path()
    
    # 填充 called_by - 清空模板占位符（需要人工维护）
    doc['called_by'] = []
    
    # 填充 calls - 规范化所有路径
    if dart_data and dart_data.get('calls'):
        doc['calls'] = [analyzer._normalize_import_path(c) for c in dart_data['calls']]
    else:
        doc['calls'] = analyzer.extract_calls()
    
    # 填充 i18n_keys
    if dart_data and 'i18n_keys' in dart_data:
        doc['i18n_keys'] = dart_data['i18n_keys']
    else:
        doc['i18n_keys'] = analyzer.extract_i18n_keys()
    
    # 填充 design_tokens
    if dart_data and 'design_tokens' in dart_data:
        doc['design_tokens'] = dart_data['design_tokens']
    else:
        doc['design_tokens'] = analyzer.extract_design_tokens()
    
    # 填充 widget_properties - 优先使用 Dart 分析器的精确数据
    if dart_data and dart_data.get('properties'):
        doc['widget_properties'] = [
            {
                'name': p['name'],
                'type': p['type'],
                'required': p['is_required'],
                'default_value': p.get('default_value'),
                'description': _extract_doc_text(p.get('doc_comment', '')),
            }
            for p in dart_data['properties']
        ]
    else:
        properties = analyzer.extract_properties()
        if properties:
            doc['widget_properties'] = properties
    
    # 填充 widget_imports
    if dart_data and dart_data.get('imports'):
        doc['widget_imports'] = dart_data['imports']
    else:
        doc['widget_imports'] = analyzer.extract_imports()
    
    return doc


def generate_page_yaml(analyzer: DartAnalyzer, template_path: Path, dart_data: Optional[Dict] = None) -> Dict:
    """生成 Page YAML
    
    Args:
        analyzer: 正则表达式分析器（降级方案）
        template_path: 模板路径
        dart_data: Dart 分析器提供的精确数据（优先使用）
    """
    with template_path.open('r', encoding='utf-8') as f:
        doc = yaml.safe_load(f)
    
    # 优先使用 Dart 分析器数据
    class_name = dart_data.get('class_name') if dart_data else analyzer.extract_class_name()
    
    # 填充基本信息
    doc['meta']['name'] = class_name or 'UnknownPage'
    doc['meta']['file_path'] = analyzer.get_relative_path()
    doc['meta']['description'] = f'{class_name} 页面'
    doc['meta']['created_date'] = datetime.now().strftime('%y%m%d')
    doc['meta']['last_updated'] = datetime.now().strftime('%y%m%d')
    
    doc['source_of_truth'] = analyzer.get_relative_path()
    
    # 优先使用 Dart 分析器的精确数据
    if dart_data:
        raw_calls = dart_data.get('calls', [])
        doc['calls'] = [analyzer._normalize_import_path(c) for c in raw_calls]
        doc['i18n_keys'] = dart_data.get('i18n_keys', [])
        doc['design_tokens'] = dart_data.get('design_tokens', [])
    else:
        # 降级到正则表达式分析
        doc['calls'] = analyzer.extract_calls()
        doc['i18n_keys'] = analyzer.extract_i18n_keys()
        doc['design_tokens'] = analyzer.extract_design_tokens()
    
    return doc


def generate_yaml(dart_file: Path, doc_type: str, template_dir: Path, output_yaml: Optional[Path] = None) -> Dict:
    """生成 YAML 文档
    
    Args:
        dart_file: Dart 源文件
        doc_type: 文档类型（widget/page/model/provider/repository/service）
        template_dir: 模板目录
        output_yaml: 输出文件路径（用于检测是否需要合并）
    """
    # 1. 尝试调用 Dart 分析器
    dart_data = call_dart_analyzer(dart_file)
    
    # 2. 创建正则表达式分析器作为降级方案
    analyzer = DartAnalyzer(dart_file)
    template_path = template_dir / f'{doc_type}_template.yaml'
    
    if not template_path.exists():
        raise FileNotFoundError(f'模板不存在: {template_path}')
    
    # 3. 生成新数据
    if doc_type == 'widget':
        new_doc = generate_widget_yaml(dart_file, analyzer, template_path, dart_data)
    elif doc_type == 'page':
        new_doc = generate_page_yaml(analyzer, template_path, dart_data)
    else:
        # 其他类型使用通用处理
        with template_path.open('r', encoding='utf-8') as f:
            new_doc = yaml.safe_load(f)
        
        class_name = dart_data.get('class_name') if dart_data else analyzer.extract_class_name()
        new_doc['meta']['name'] = class_name or 'Unknown'
        new_doc['meta']['file_path'] = analyzer.get_relative_path()
        new_doc['meta']['created_date'] = datetime.now().strftime('%y%m%d')
        new_doc['meta']['last_updated'] = datetime.now().strftime('%y%m%d')
        new_doc['source_of_truth'] = analyzer.get_relative_path()
        
        if dart_data:
            # 规范化 calls 路径
            raw_calls = dart_data.get('calls', [])
            new_doc['calls'] = [analyzer._normalize_import_path(c) for c in raw_calls]
            new_doc['i18n_keys'] = dart_data.get('i18n_keys', [])
            new_doc['design_tokens'] = dart_data.get('design_tokens', [])
        else:
            new_doc['calls'] = analyzer.extract_calls()
    
    # 4. 直接返回新生成的数据，不合并旧数据
    # 原因：重新生成时应该完全替换，确保数据质量
    return new_doc


def main():
    if len(sys.argv) < 4:
        print('Usage: yaml_generator.py <dart_file> <output_yaml> <type>')
        sys.exit(1)
    
    dart_file = Path(sys.argv[1])
    output_yaml = Path(sys.argv[2])
    doc_type = sys.argv[3]
    
    if not dart_file.exists():
        print(f'Dart 文件不存在: {dart_file}')
        sys.exit(1)
    
    template_dir = ROOT / 'documents' / 'templates'
    
    try:
        # 传递 output_yaml 以支持合并模式
        doc = generate_yaml(dart_file, doc_type, template_dir, output_yaml)
        
        # 确保输出目录存在
        output_yaml.parent.mkdir(parents=True, exist_ok=True)
        
        # 写入 YAML
        with output_yaml.open('w', encoding='utf-8') as f:
            yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False)
        
        print(f'[yaml_generator] 已生成: {output_yaml}')
        print(f'[yaml_generator] 类名: {doc["meta"]["name"]}')
        print(f'[yaml_generator] i18n 键: {len(doc.get("i18n_keys", []))} 个')
        print(f'[yaml_generator] 设计令牌: {len(doc.get("design_tokens", []))} 个')
        print(f'[yaml_generator] 模式: 完全覆盖（不保留旧数据）')
        
    except Exception as e:
        print(f'生成失败: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

