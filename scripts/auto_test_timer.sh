#!/bin/bash
# 自动测试计时器功能并反复调整
# 用法: ./scripts/auto_test_timer.sh

set -e

MAX_ATTEMPTS=5
ATTEMPT=1

echo "🚀 开始自动测试计时器功能..."
echo ""

# 检查设备连接
DEVICE=$(flutter devices 2>&1 | grep -E "•|device" | head -1 | awk '{print $NF}' | tr -d '()' || echo "")

if [ -z "$DEVICE" ]; then
    echo "❌ 未找到连接的设备，请连接设备后重试"
    exit 1
fi

echo "✅ 找到设备: $DEVICE"
echo ""

# 构建应用
echo "📦 构建应用..."
flutter build apk --debug

# 安装应用
echo "📱 安装应用到设备..."
flutter install -d "$DEVICE"

# 运行应用并监控日志
echo "🔍 启动应用并监控日志..."
echo "请在应用中点击播放按钮，脚本将自动检测崩溃..."
echo ""

# 启动应用
adb shell am start -n com.granoflow.app/.MainActivity

# 等待几秒让应用启动
sleep 3

# 监控日志，查找崩溃
echo "监控日志中..."
timeout 30 adb logcat -c  # 清空日志
timeout 30 adb logcat | grep -E "AndroidRuntime|FATAL|flutter" | while read line; do
    echo "$line"
    if echo "$line" | grep -q "FATAL EXCEPTION"; then
        echo ""
        echo "❌ 检测到崩溃！"
        echo "错误信息:"
        adb logcat -d | grep -A 20 "FATAL EXCEPTION" | tail -25
        exit 1
    fi
done || {
    echo ""
    echo "✅ 30秒内未检测到崩溃，测试通过！"
    exit 0
}

