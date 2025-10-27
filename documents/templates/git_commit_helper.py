#!/usr/bin/env python3
"""
Step-Done Git提交处理工具
用于处理 step-done 执行完成后的自动提交
"""

import subprocess
import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, Tuple
from error_logging_helper import StepDoneErrorLogger

class StepDoneGitHandler:
    def __init__(self, log_directory: str = "documents/plan-logs"):
        self.logger = StepDoneErrorLogger(log_directory)
        self.max_retries = 5
    
    def get_last_commit_time(self) -> Optional[datetime]:
        """获取上次提交时间"""
        try:
            result = subprocess.run(
                ['git', 'log', '-1', '--format=%ct'],
                capture_output=True,
                text=True,
                check=True
            )
            timestamp = int(result.stdout.strip())
            return datetime.fromtimestamp(timestamp)
        except subprocess.CalledProcessError as e:
            self.logger.log_error(
                step_name="get_last_commit_time",
                error_content=str(e),
                estimated_cause="git log命令执行失败",
                solution_attempted="检查git仓库状态",
                failure_manifestation="无法获取上次提交时间",
                excluded_possibilities="排除了权限问题",
                retry_count=0
            )
            return None
    
    def should_run_precommit(self) -> bool:
        """判断是否应该运行pre-commit"""
        last_commit_time = self.get_last_commit_time()
        if last_commit_time is None:
            return False
        
        time_diff = datetime.now() - last_commit_time
        return time_diff < timedelta(minutes=30)
    
    def run_precommit(self) -> Tuple[bool, str]:
        """运行pre-commit检查"""
        try:
            result = subprocess.run(
                ['pre-commit', 'run', '--all-files'],
                capture_output=True,
                text=True,
                check=True
            )
            # 记录pre-commit成功日志
            self.logger.log_error(
                step_name="precommit_check",
                error_content="pre-commit检查通过",
                estimated_cause="代码质量检查通过",
                solution_attempted="无需处理",
                failure_manifestation="无",
                excluded_possibilities="无",
                retry_count=0,
                max_retries=5
            )
            return True, result.stdout
        except subprocess.CalledProcessError as e:
            return False, e.stderr
    
    def build_suggested_commit(self, iteration: Optional[str] = None) -> str:
        """生成建议的git提交命令（仅供手动执行）"""
        title = f"chore(step-done): 补充YAML与测试 ({iteration or 'YYMMDD-N'})"
        body = (
            "说明: 按 step-done 文档补充/更新规范YAML与对应测试, 已通过 pre-commit。\n"
            "注意: 如涉及文档/脚手架调整，请在提交体中列出清单。"
        )
        return (
            "git add -A\n"
            f"git commit -m \"{title}\" -m \"{body}\"\n"
        )
    
    def handle_commit_with_retry(self) -> bool:
        """仅处理pre-commit检查；不执行自动提交"""
        retry_count = 0
        
        while retry_count < self.max_retries:
            try:
                # 检查是否需要运行pre-commit
                if self.should_run_precommit():
                    print("距离上次提交未超过30分钟，运行pre-commit检查...")
                    success, output = self.run_precommit()
                    
                    if not success:
                        retry_count += 1
                        self.logger.log_error(
                            step_name="precommit_check",
                            error_content=output,
                            estimated_cause="pre-commit检查失败",
                            solution_attempted="修复代码问题后重试",
                            failure_manifestation="pre-commit检查未通过",
                            excluded_possibilities="排除了权限问题",
                            retry_count=retry_count,
                            max_retries=self.max_retries
                        )
                        
                        if retry_count >= self.max_retries:
                            print(f"pre-commit检查失败，已达到最大重试次数({self.max_retries})")
                            return False
                        
                        print(f"pre-commit检查失败，第{retry_count}次重试...")
                        continue
                    
                    print("pre-commit检查通过")
                else:
                    print("距离上次提交超过30分钟，仍执行pre-commit检查...")
                    success, output = self.run_precommit()
                    if not success:
                        print(output)
                        return False

                # 仅输出建议提交命令
                print("建议提交命令（请手动执行）：")
                print(self.build_suggested_commit())
                return True
                    
            except Exception as e:
                retry_count += 1
                self.logger.log_error(
                    step_name="handle_commit_with_retry",
                    error_content=str(e),
                    estimated_cause="未知错误",
                    solution_attempted="重试整个流程",
                    failure_manifestation="处理过程中出现异常",
                    excluded_possibilities="排除了权限问题",
                    retry_count=retry_count,
                    max_retries=self.max_retries
                )
                
                if retry_count >= self.max_retries:
                    print(f"处理过程中出现异常，已达到最大重试次数({self.max_retries})")
                    return False
                
                print(f"处理过程中出现异常，第{retry_count}次重试...")
                continue
        
        return False
    
    def get_commit_status(self) -> Dict[str, Any]:
        """获取提交状态"""
        last_commit_time = self.get_last_commit_time()
        should_precommit = self.should_run_precommit()
        
        return {
            "last_commit_time": last_commit_time.isoformat() if last_commit_time else None,
            "should_run_precommit": should_precommit,
            "max_retries": self.max_retries,
            "log_summary": self.logger.get_log_summary()
        }

# 使用示例
if __name__ == "__main__":
    handler = StepDoneGitHandler()
    
    print("Git提交状态:")
    status = handler.get_commit_status()
    print(json.dumps(status, indent=2, ensure_ascii=False))
    
    print("\n开始处理提交...")
    success = handler.handle_commit_with_retry()
    
    if success:
        print("✅ 提交处理成功")
    else:
        print("❌ 提交处理失败")
        print("错误日志摘要:")
        print(json.dumps(handler.logger.get_log_summary(), indent=2, ensure_ascii=False))