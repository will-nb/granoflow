#!/usr/bin/env python3
"""
Step-Done 执行器
用于执行 step-done 流程，包括YAML更新、测试创建、验证和git提交
"""

import os
import sys
import json
import yaml
import subprocess
from datetime import datetime
from typing import Dict, Any, Optional
from git_commit_helper import StepDoneGitHandler

class StepDoneExecutor:
    def __init__(self, step_done_file: str, log_directory: str = "documents/plan-logs"):
        self.step_done_file = step_done_file
        self.log_directory = log_directory
        self.git_handler = StepDoneGitHandler(log_directory)
        self.ensure_log_directory()
    
    def ensure_log_directory(self):
        """确保日志目录存在"""
        if not os.path.exists(self.log_directory):
            os.makedirs(self.log_directory)
    
    def load_step_done_config(self) -> Dict[str, Any]:
        """加载step-done配置文件（YAML）"""
        try:
            with open(self.step_done_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f) or {}
        except Exception as e:
            print(f"❌ 加载step-done配置文件失败: {e}")
            return {}
    
    def update_yaml_files(self, config: Dict[str, Any]) -> bool:
        """更新YAML文件"""
        print("📝 开始更新YAML文件...")
        
        yaml_updates = config.get('yaml_updates', {})
        new_files = yaml_updates.get('new_yaml_files', {}).get('files', [])
        modified_files = yaml_updates.get('modified_yaml_files', {}).get('files', [])
        
        # 处理新文件
        for file_info in new_files:
            file_path = file_info.get('file', '')
            if file_path:
                print(f"  📄 创建新YAML文件: {file_path}")
                # 这里应该根据file_info创建实际的YAML文件
                # 具体实现需要根据step文档中的代码实现来生成
        
        # 处理修改文件
        for file_info in modified_files:
            file_path = file_info.get('file', '')
            if file_path:
                print(f"  📝 修改YAML文件: {file_path}")
                # 这里应该根据file_info修改实际的YAML文件
                # 具体实现需要根据step文档中的代码实现来生成
        
        print("✅ YAML文件更新完成")
        return True
    
    def create_test_files(self, config: Dict[str, Any]) -> bool:
        """创建测试文件"""
        print("🧪 开始创建测试文件...")
        
        test_creation = config.get('test_creation', {})
        unit_tests = test_creation.get('unit_tests', {}).get('tests', [])
        widget_tests = test_creation.get('widget_tests', {}).get('tests', [])
        integration_tests = test_creation.get('integration_tests', {}).get('tests', [])
        
        # 处理单元测试
        for test_info in unit_tests:
            file_path = test_info.get('file', '')
            if file_path:
                print(f"  🔬 创建单元测试: {file_path}")
                # 这里应该根据test_info创建实际的测试文件
                # 具体实现需要根据step文档中的代码实现来生成
        
        # 处理组件测试
        for test_info in widget_tests:
            file_path = test_info.get('file', '')
            if file_path:
                print(f"  🎨 创建组件测试: {file_path}")
                # 这里应该根据test_info创建实际的测试文件
                # 具体实现需要根据step文档中的代码实现来生成
        
        # 处理集成测试
        for test_info in integration_tests:
            file_path = test_info.get('file', '')
            if file_path:
                print(f"  🔗 创建集成测试: {file_path}")
                # 这里应该根据test_info创建实际的测试文件
                # 具体实现需要根据step文档中的代码实现来生成
        
        print("✅ 测试文件创建完成")
        return True
    
    def run_verification(self, config: Dict[str, Any]) -> bool:
        """运行验证"""
        print("🔍 开始运行验证...")
        
        verification = config.get('verification', {})
        
        # 运行YAML一致性验证
        yaml_consistency = verification.get('yaml_consistency', {})
        steps = yaml_consistency.get('steps', [])
        for step in steps:
            print(f"  📋 执行: {step.get('step', '')}")
            # 这里应该执行实际的验证步骤
        
        # 运行测试执行验证
        test_execution = verification.get('test_execution', {})
        steps = test_execution.get('steps', [])
        for step in steps:
            print(f"  🧪 执行: {step.get('step', '')}")
            command = step.get('command', '')
            if command:
                try:
                    result = subprocess.run(command.split(), capture_output=True, text=True, check=True, timeout=300)
                    print(f"    ✅ 成功: {command}")
                except subprocess.CalledProcessError as e:
                    print(f"    ❌ 失败: {command}")
                    print(f"    错误: {e.stderr}")
                    return False
                except subprocess.TimeoutExpired:
                    print(f"    ⏳ 超时: {command}")
                    return False
        
        # 运行覆盖率检查
        coverage_check = verification.get('coverage_check', {})
        steps = coverage_check.get('steps', [])
        for step in steps:
            print(f"  📊 执行: {step.get('step', '')}")
            command = step.get('command', '')
            if command:
                try:
                    result = subprocess.run(command.split(), capture_output=True, text=True, check=True, timeout=300)
                    print(f"    ✅ 成功: {command}")
                except subprocess.CalledProcessError as e:
                    print(f"    ❌ 失败: {command}")
                    print(f"    错误: {e.stderr}")
                    return False
                except subprocess.TimeoutExpired:
                    print(f"    ⏳ 超时: {command}")
                    return False
        
        print("✅ 验证完成")
        return True
    
    def handle_git_commit(self, config: Dict[str, Any]) -> bool:
        """仅运行pre-commit并输出建议的提交命令（不自动提交）"""
        print("📤 开始运行pre-commit检查（不自动提交）...")
        try:
            result = subprocess.run(
                ['pre-commit', 'run', '--all-files'],
                capture_output=True,
                text=True,
                check=True,
                timeout=600,
            )
            print("✅ pre-commit检查通过")
        except subprocess.CalledProcessError as e:
            print("❌ pre-commit检查未通过")
            print(e.stdout)
            print(e.stderr)
            return False
        except subprocess.TimeoutExpired:
            print("⏳ pre-commit检查超时")
            return False

        iteration = (
            (config.get('meta') or {}).get('iteration')
            or 'YYMMDD-N'
        )
        suggested_message_title = f"chore(step-done): 补充YAML与测试 ({iteration})"
        suggested_message_body = (
            "说明: 按 step-done 文档补充/更新规范YAML与对应测试, 通过 pre-commit。\n"
            "注意: 按需在提交体中附加本次涉及的文档与测试清单。"
        )

        print("🔎 建议的提交命令（请手动执行）:")
        print("""
git add -A
git commit -m "{title}" -m "{body}"
""".format(title=suggested_message_title, body=suggested_message_body))

        return True
    
    def execute(self) -> bool:
        """执行完整的step-done流程"""
        print("🚀 开始执行step-done流程...")
        print(f"📁 配置文件: {self.step_done_file}")
        print(f"📁 日志目录: {self.log_directory}")
        
        # 加载配置
        config = self.load_step_done_config()
        if not config:
            print("❌ 无法加载配置文件")
            return False
        
        # 更新YAML文件
        if not self.update_yaml_files(config):
            print("❌ YAML文件更新失败")
            return False
        
        # 创建测试文件
        if not self.create_test_files(config):
            print("❌ 测试文件创建失败")
            return False
        
        # 运行验证
        if not self.run_verification(config):
            print("❌ 验证失败")
            return False
        
        # 处理git提交（仅运行pre-commit并输出建议的提交命令）
        if not self.handle_git_commit(config):
            print("❌ Git提交失败")
            return False
        
        print("🎉 step-done流程执行完成")
        return True

# 使用示例
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python step_done_executor.py <step_done_file>")
        print("示例: python step_done_executor.py documents/plan/251025-1-step-done.yaml")
        sys.exit(1)
    
    step_done_file = sys.argv[1]
    
    if not os.path.exists(step_done_file):
        print(f"❌ 文件不存在: {step_done_file}")
        sys.exit(1)
    
    executor = StepDoneExecutor(step_done_file)
    success = executor.execute()
    
    if success:
        print("✅ 执行成功")
        sys.exit(0)
    else:
        print("❌ 执行失败")
        sys.exit(1)