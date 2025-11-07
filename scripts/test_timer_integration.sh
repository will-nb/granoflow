#!/bin/bash
# 计时器集成测试脚本
# 自动运行集成测试并报告结果

set -e

echo "🔍 检查设备连接..."
DEVICE=$(flutter devices | grep -E "•|device" | head -1 | awk '{print $NF}' | tr -d '()')

if [ -z "$DEVICE" ]; then
    echo "❌ 未找到连接的设备"
    exit 1
fi

echo "✅ 找到设备: $DEVICE"

echo ""
echo "🧪 运行计时器启动崩溃测试..."
flutter test integration_test/timer_start_crash_test.dart -d "$DEVICE" || {
    echo "❌ 测试失败，正在检查日志..."
    adb logcat -d | grep -A 20 "AndroidRuntime" | tail -30
    exit 1
}

echo ""
echo "✅ 所有测试通过！"

