#!/usr/bin/env python3
"""
批量生成 architecture YAML 文档

清空并重新生成 documents/architecture 下六大核心类型的 YAML 文档：
- models/
- pages/
- widgets/
- providers/
- repositories/
- services/

用法：
    python scripts/yaml_create_all.py [--dry-run] [--no-backup]

实现：
    复用 yaml_generator.py 的生成逻辑，本脚本只负责批量调度
"""
import sys
import shutil
import yaml
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Tuple

ROOT = Path(__file__).resolve().parents[1]

# 导入 yaml_generator 的功能（复用代码，避免重复实现）
sys.path.insert(0, str(ROOT / 'scripts'))
from yaml_generator import generate_yaml

# 导入并发库
import concurrent.futures
import threading

# 线程安全的打印锁
_print_lock = threading.Lock()

def thread_safe_print(msg: str):
    """线程安全的打印函数"""
    with _print_lock:
        print(msg)

# 六大核心类型的映射
TYPE_MAPPINGS = {
    'models': {
        'yaml_dir': ROOT / 'documents/architecture/models',
        'dart_dir': ROOT / 'lib/data/models',
        'type': 'model',
    },
    'pages': {
        'yaml_dir': ROOT / 'documents/architecture/pages',
        'dart_dirs': [
            ROOT / 'lib/presentation/home',
            ROOT / 'lib/presentation/tasks',
            ROOT / 'lib/presentation/inbox',
            ROOT / 'lib/presentation/achievements',
            ROOT / 'lib/presentation/timer',
            ROOT / 'lib/presentation/completion_management',
        ],
        'type': 'page',
        'pattern': '*_page.dart',
    },
    'widgets': {
        'yaml_dir': ROOT / 'documents/architecture/widgets',
        'dart_dir': ROOT / 'lib/presentation/widgets',
        'type': 'widget',
    },
    'providers': {
        'yaml_dir': ROOT / 'documents/architecture/providers',
        'dart_dir': ROOT / 'lib/core/providers',
        'type': 'provider',
    },
    'repositories': {
        'yaml_dir': ROOT / 'documents/architecture/repositories',
        'dart_dir': ROOT / 'lib/data/repositories',
        'type': 'repository',
    },
    'services': {
        'yaml_dir': ROOT / 'documents/architecture/services',
        'dart_dir': ROOT / 'lib/core/services',
        'type': 'service',
    },
}


def backup_architecture_dir() -> Tuple[Path, Path]:
    """备份整个 architecture 目录（重命名）
    
    Returns:
        (backup_path, routers_yaml_path): 备份路径和 routers.yaml 路径
    """
    arch_dir = ROOT / 'documents/architecture'
    
    if not arch_dir.exists():
        print("  ⚠️  architecture 目录不存在，将创建新目录")
        return None, None
    
    # 保存 routers.yaml（特殊情况，需要保留）
    routers_yaml = arch_dir / 'routers.yaml'
    routers_backup = None
    if routers_yaml.exists():
        routers_backup = ROOT / 'documents/temp/routers.yaml.temp'
        routers_backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(routers_yaml, routers_backup)
    
    timestamp = datetime.now().strftime('%y%m%d-%H%M%S')
    backup_name = f'architecture-{timestamp}'
    backup_path = ROOT / 'documents' / backup_name
    
    # 直接重命名整个目录
    arch_dir.rename(backup_path)
    
    return backup_path, routers_backup


def is_enum_file(dart_file: Path) -> bool:
    """检测 Dart 文件是否是 enum 定义
    
    Args:
        dart_file: Dart 文件路径
        
    Returns:
        bool: 如果文件主要定义是 enum，返回 True
    """
    try:
        content = dart_file.read_text(encoding='utf-8')
        
        # 移除注释和字符串，避免误判
        lines = content.split('\n')
        code_lines = []
        
        for line in lines:
            # 移除单行注释
            if '//' in line:
                line = line[:line.index('//')]
            # 跳过空行
            line = line.strip()
            if line:
                code_lines.append(line)
        
        code = ' '.join(code_lines)
        
        # 检测是否有 enum 定义（排除在注释和字符串中的情况）
        # 简单规则：如果有 "enum XXX {" 或 "enum XXX{" 模式，认为是 enum 文件
        import re
        enum_pattern = r'\benum\s+\w+\s*\{'
        
        if re.search(enum_pattern, code):
            # 进一步检查：enum 是否是文件的主要内容
            # 检查是否有 class/abstract class/mixin 定义
            class_pattern = r'\b(class|abstract\s+class|mixin)\s+\w+'
            
            # 如果只有 enum，没有 class/mixin，则认为是 enum 文件
            if not re.search(class_pattern, code):
                return True
        
        return False
        
    except Exception as e:
        # 读取失败，保守起见不跳过
        return False


def find_dart_files(config: dict) -> List[Path]:
    """查找 Dart 文件（排除 enum 文件）"""
    dart_files = []
    
    if 'dart_dir' in config:
        # 单个目录
        dart_dir = config['dart_dir']
        if dart_dir.exists():
            pattern = config.get('pattern', '*.dart')
            # 排除生成的文件和 enum 文件
            for f in dart_dir.glob(pattern):
                if not f.name.endswith('.g.dart') and not f.name.endswith('.freezed.dart'):
                    # ✅ 新增：跳过 enum 文件
                    if not is_enum_file(f):
                        dart_files.append(f)
                    else:
                        thread_safe_print(f"  ⏭️  跳过 enum 文件: {f.name}")
    
    elif 'dart_dirs' in config:
        # 多个目录
        for dart_dir in config['dart_dirs']:
            if dart_dir.exists():
                pattern = config.get('pattern', '*.dart')
                for f in dart_dir.glob(pattern):
                    if not f.name.endswith('.g.dart') and not f.name.endswith('.freezed.dart'):
                        # ✅ 新增：跳过 enum 文件
                        if not is_enum_file(f):
                            dart_files.append(f)
                        else:
                            thread_safe_print(f"  ⏭️  跳过 enum 文件: {f.name}")
    
    return dart_files


def generate_yaml_file(dart_file: Path, output_yaml: Path, doc_type: str) -> Tuple[bool, str]:
    """生成单个 YAML 文件（复用 yaml_generator.py 的逻辑）"""
    try:
        template_dir = ROOT / 'documents' / 'templates'
        
        # 直接调用 yaml_generator 的函数（复用代码）
        doc = generate_yaml(dart_file, doc_type, template_dir, output_yaml)
        
        # 确保输出目录存在
        output_yaml.parent.mkdir(parents=True, exist_ok=True)
        
        # 写入 YAML
        with output_yaml.open('w', encoding='utf-8') as f:
            yaml.safe_dump(doc, f, allow_unicode=True, sort_keys=False)
        
        return True, f"生成成功: {doc['meta']['name']}"
    except Exception as e:
        return False, str(e)


def process_category(category: str, config: dict, dry_run: bool = False) -> dict:
    """处理单个类别"""
    stats = {
        'category': category,
        'found': 0,
        'generated': 0,
        'failed': 0,
        'errors': [],
    }
    
    yaml_dir = config['yaml_dir']
    doc_type = config['type']
    
    # 查找 Dart 文件
    dart_files = find_dart_files(config)
    stats['found'] = len(dart_files)
    
    if not dart_files:
        print(f"  ⚠️  未找到 {category} 的 Dart 文件")
        return stats
    
    print(f"  找到 {len(dart_files)} 个 {category} 文件")
    
    if dry_run:
        for dart_file in dart_files:
            print(f"    - {dart_file.name}")
        return stats
    
    # 创建目录（architecture 目录已经被重命名，这里是全新的）
    yaml_dir.mkdir(parents=True, exist_ok=True)
    
    # 定义单文件处理函数（供并发调用）
    def process_single_file(dart_file: Path) -> tuple:
        """处理单个文件（供并发调用）"""
        yaml_name = dart_file.stem + '.yaml'
        output_yaml = yaml_dir / yaml_name
        success, message = generate_yaml_file(dart_file, output_yaml, doc_type)
        return (dart_file.name, yaml_name, success, message)
    
    # 使用线程池并发处理（6 个工作线程）
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
        futures = [executor.submit(process_single_file, df) for df in dart_files]
        
        for future in concurrent.futures.as_completed(futures):
            dart_name, yaml_name, success, message = future.result()
            
            if success:
                stats['generated'] += 1
                thread_safe_print(f"    ✅ {yaml_name}")
            else:
                stats['failed'] += 1
                stats['errors'].append((dart_name, message))
                thread_safe_print(f"    ❌ {yaml_name}: {message[:100]}")
    
    return stats


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='批量生成所有六大核心类型的 architecture YAML 文档'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='模拟运行，不实际生成文件'
    )
    parser.add_argument(
        '--no-backup',
        action='store_true',
        help='不创建备份'
    )
    
    args = parser.parse_args()
    
    # 记录开始时间
    import time
    start_time = time.time()
    
    print("=" * 60)
    print("批量生成 Architecture YAML 文档")
    print("=" * 60)
    print("\n📝 将重新生成所有六大核心类型的 YAML 文档：")
    print("   - models/")
    print("   - pages/")
    print("   - widgets/")
    print("   - providers/")
    print("   - repositories/")
    print("   - services/\n")
    
    if args.dry_run:
        print("🔍 模拟运行模式（不会修改文件）\n")
    
    # 处理所有类别
    categories = list(TYPE_MAPPINGS.keys())
    
    # 备份：重命名整个 architecture 目录
    routers_backup = None
    if not args.dry_run and not args.no_backup:
        print("📦 备份 architecture 目录...")
        backup_path, routers_backup = backup_architecture_dir()
        if backup_path:
            print(f"  ✅ 已重命名为: {backup_path.name}")
            if routers_backup:
                print(f"  ✅ routers.yaml 已保存（稍后恢复）\n")
            else:
                print()
        else:
            print()
    
    # 处理每个类别
    print("🔨 生成 YAML 文档...\n")
    all_stats = []
    
    for category in categories:
        print(f"处理 {category.upper()}:")
        config = TYPE_MAPPINGS[category]
        stats = process_category(category, config, args.dry_run)
        all_stats.append(stats)
        print()
    
    # 恢复 routers.yaml（特殊保留）
    if not args.dry_run and routers_backup and routers_backup.exists():
        arch_dir = ROOT / 'documents/architecture'
        routers_dest = arch_dir / 'routers.yaml'
        shutil.copy2(routers_backup, routers_dest)
        routers_backup.unlink()  # 删除临时文件
        print("📋 已恢复 routers.yaml（作为路由地图保留）\n")
    
    # 运行 Linter
    if not args.dry_run:
        print("🔍 运行架构 Linter...")
        try:
            result = subprocess.run(
                ['python3', str(ROOT / 'scripts/architecture_linter.py')],
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode == 0:
                print("  ✅ Linter 检查通过")
            else:
                print(f"  ⚠️  Linter 警告:\n{result.stdout}")
        except Exception as e:
            print(f"  ❌ Linter 执行失败: {e}")
    
    # 打印总结
    print("\n" + "=" * 60)
    print("总结")
    print("=" * 60)
    
    total_found = sum(s['found'] for s in all_stats)
    total_generated = sum(s['generated'] for s in all_stats)
    total_failed = sum(s['failed'] for s in all_stats)
    
    for stats in all_stats:
        cat = stats['category']
        print(f"{cat:15} | 找到: {stats['found']:3} | 生成: {stats['generated']:3} | 失败: {stats['failed']:3}")
    
    print("-" * 60)
    print(f"{'总计':15} | 找到: {total_found:3} | 生成: {total_generated:3} | 失败: {total_failed:3}")
    
    if total_failed > 0:
        print("\n❌ 失败详情:")
        for stats in all_stats:
            if stats['errors']:
                print(f"\n  {stats['category']}:")
                for filename, error in stats['errors']:
                    print(f"    - {filename}: {error[:100]}")
        sys.exit(1)
    
    if not args.dry_run:
        # 计算并打印总运行时间
        elapsed_time = time.time() - start_time
        minutes = int(elapsed_time // 60)
        seconds = elapsed_time % 60
        
        if minutes > 0:
            time_str = f"{minutes} 分 {seconds:.1f} 秒"
        else:
            time_str = f"{seconds:.1f} 秒"
        
        print(f"\n✅ 所有 YAML 文档已成功生成！")
        print(f"⏱️  总运行时间: {time_str}")


if __name__ == '__main__':
    main()

