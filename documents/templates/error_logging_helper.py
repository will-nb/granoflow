#!/usr/bin/env python3
"""
Step-Done 错误日志记录工具
用于记录 step-done 执行过程中的错误和重试信息
"""

import json
import os
from datetime import datetime
from typing import Dict, Any, Optional

class StepDoneErrorLogger:
    def __init__(self, log_directory: str = "documents/plan-logs"):
        self.log_directory = log_directory
        self.ensure_log_directory()
    
    def ensure_log_directory(self):
        """确保日志目录存在"""
        if not os.path.exists(self.log_directory):
            os.makedirs(self.log_directory)
    
    def log_error(self, 
                  step_name: str,
                  error_content: str,
                  estimated_cause: str,
                  solution_attempted: str,
                  failure_manifestation: str,
                  excluded_possibilities: str,
                  retry_count: int = 0,
                  max_retries: int = 5) -> str:
        """
        记录错误信息到JSON日志文件
        
        Args:
            step_name: 当前步骤名称
            error_content: 具体报错内容
            estimated_cause: 估计的错误原因
            solution_attempted: 尝试的解决方式
            failure_manifestation: 失败的具体表现
            excluded_possibilities: 排除的可能性
            retry_count: 当前重试次数
            max_retries: 最大重试次数
        
        Returns:
            日志文件路径
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_filename = f"step_done_error_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        log_path = os.path.join(self.log_directory, log_filename)
        
        log_entry = {
            "timestamp": timestamp,
            "step_name": step_name,
            "error_content": error_content,
            "estimated_cause": estimated_cause,
            "solution_attempted": solution_attempted,
            "failure_manifestation": failure_manifestation,
            "excluded_possibilities": excluded_possibilities,
            "retry_count": retry_count,
            "max_retries": max_retries,
            "status": "retrying" if retry_count < max_retries else "failed"
        }
        
        with open(log_path, 'w', encoding='utf-8') as f:
            json.dump(log_entry, f, ensure_ascii=False, indent=2)
        
        return log_path
    
    def should_retry(self, retry_count: int, max_retries: int = 5) -> bool:
        """判断是否应该重试"""
        return retry_count < max_retries
    
    def should_auto_exit(self, retry_count: int, max_retries: int = 5) -> bool:
        """判断是否应该自动退出"""
        return retry_count >= max_retries
    
    def get_log_summary(self) -> Dict[str, Any]:
        """获取日志摘要"""
        log_files = [f for f in os.listdir(self.log_directory) if f.endswith('.json')]
        
        total_errors = len(log_files)
        failed_errors = 0
        retrying_errors = 0
        
        for log_file in log_files:
            log_path = os.path.join(self.log_directory, log_file)
            try:
                with open(log_path, 'r', encoding='utf-8') as f:
                    log_entry = json.load(f)
                    if log_entry.get('status') == 'failed':
                        failed_errors += 1
                    elif log_entry.get('status') == 'retrying':
                        retrying_errors += 1
            except Exception:
                continue
        
        return {
            "total_errors": total_errors,
            "failed_errors": failed_errors,
            "retrying_errors": retrying_errors,
            "log_directory": self.log_directory
        }

# 使用示例
if __name__ == "__main__":
    logger = StepDoneErrorLogger()
    
    # 记录一个错误
    log_path = logger.log_error(
        step_name="git_commit",
        error_content="fatal: not a git repository",
        estimated_cause="当前目录不是git仓库",
        solution_attempted="检查当前目录，切换到正确的git仓库目录",
        failure_manifestation="git命令执行失败，提示不是git仓库",
        excluded_possibilities="排除了权限问题和网络问题",
        retry_count=1,
        max_retries=5
    )
    
    print(f"错误日志已记录到: {log_path}")
    print(f"日志摘要: {logger.get_log_summary()}")