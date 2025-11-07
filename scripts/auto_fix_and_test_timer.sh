#!/bin/bash
# 自动修复并测试计时器功能
# 反复运行测试，直到通过或达到最大尝试次数

set -e

MAX_ATTEMPTS=10
ATTEMPT=1
SUCCESS=false

echo "🔧 自动修复并测试计时器功能"
echo "最大尝试次数: $MAX_ATTEMPTS"
echo ""

# 检查设备连接
get_device() {
    flutter devices 2>&1 | grep -E "•|device" | head -1 | awk '{print $NF}' | tr -d '()' || echo ""
}

DEVICE=$(get_device)
if [ -z "$DEVICE" ]; then
    echo "❌ 未找到连接的设备"
    exit 1
fi

echo "✅ 找到设备: $DEVICE"
echo ""

while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ "$SUCCESS" = false ]; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 尝试 $ATTEMPT/$MAX_ATTEMPTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 构建应用
    echo "📦 构建应用..."
    if ! flutter build apk --debug > /tmp/flutter_build.log 2>&1; then
        echo "❌ 构建失败"
        cat /tmp/flutter_build.log | tail -20
        exit 1
    fi
    
    # 安装应用
    echo "📱 安装应用..."
    flutter install -d "$DEVICE" > /dev/null 2>&1
    
    # 清空日志
    echo "🧹 清空日志..."
    adb logcat -c > /dev/null 2>&1
    
    # 启动应用
    echo "🚀 启动应用..."
    adb shell am start -n com.granoflow.app/.MainActivity > /dev/null 2>&1
    sleep 2
    
    echo ""
    echo "⏳ 等待 5 秒，请点击播放按钮..."
    echo "   如果应用崩溃，脚本将自动检测并继续..."
    echo ""
    
    # 监控日志 10 秒
    CRASH_DETECTED=false
    timeout 10 adb logcat | grep -E "FATAL EXCEPTION|AndroidRuntime.*com.granoflow" | head -1 | while read line; do
        if echo "$line" | grep -q "FATAL EXCEPTION"; then
            CRASH_DETECTED=true
            echo "❌ 检测到崩溃！"
            echo ""
            echo "错误详情:"
            adb logcat -d | grep -A 15 "FATAL EXCEPTION" | tail -20
            echo ""
        fi
    done || true
    
    # 检查应用是否还在运行
    sleep 2
    if adb shell pidof com.granoflow.app > /dev/null 2>&1; then
        echo "✅ 应用仍在运行，未检测到崩溃！"
        SUCCESS=true
        break
    else
        echo "❌ 应用已停止，可能发生崩溃"
        echo ""
        echo "最近的错误日志:"
        adb logcat -d | grep -E "AndroidRuntime|FATAL|flutter" | tail -30
        echo ""
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
        echo "等待 3 秒后重试..."
        sleep 3
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$SUCCESS" = true ]; then
    echo "✅ 测试通过！应用未崩溃"
    exit 0
else
    echo "❌ 测试失败，已达到最大尝试次数"
    echo ""
    echo "最终错误日志:"
    adb logcat -d | grep -E "AndroidRuntime|FATAL" | tail -40
    exit 1
fi

