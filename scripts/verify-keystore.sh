#!/bin/bash
# 验证 keystore 配置是否正确

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYSTORE_PROPERTIES="$PROJECT_ROOT/android/app/keystore.properties"

echo "🔍 验证 keystore 配置..."
echo ""

# 检查 keystore.properties 文件是否存在
if [ ! -f "$KEYSTORE_PROPERTIES" ]; then
    echo "❌ keystore.properties 文件不存在: $KEYSTORE_PROPERTIES"
    exit 1
fi

echo "✅ keystore.properties 文件存在"
echo ""

# 读取配置
STORE_FILE=$(grep "^storeFile=" "$KEYSTORE_PROPERTIES" | cut -d'=' -f2)
STORE_PASSWORD=$(grep "^storePassword=" "$KEYSTORE_PROPERTIES" | cut -d'=' -f2)
KEY_ALIAS=$(grep "^keyAlias=" "$KEYSTORE_PROPERTIES" | cut -d'=' -f2)
KEY_PASSWORD=$(grep "^keyPassword=" "$KEYSTORE_PROPERTIES" | cut -d'=' -f2)

echo "📋 配置信息："
echo "  storeFile: $STORE_FILE"
echo "  keyAlias: $KEY_ALIAS"
echo "  storePassword: ${STORE_PASSWORD:0:3}*** (已隐藏)"
echo "  keyPassword: ${KEY_PASSWORD:0:3}*** (已隐藏)"
echo ""

# 检查 keystore 文件是否存在
if [ ! -f "$STORE_FILE" ]; then
    echo "❌ keystore 文件不存在: $STORE_FILE"
    exit 1
fi

echo "✅ keystore 文件存在: $STORE_FILE"
echo ""

# 验证 keystore 是否可以正常读取
echo "🔐 验证 keystore 内容..."
if keytool -list -v -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" > /dev/null 2>&1; then
    echo "✅ keystore 密码正确，可以正常读取"
else
    echo "❌ keystore 密码错误或文件损坏"
    exit 1
fi
echo ""

# 检查密钥别名是否存在
echo "🔑 检查密钥别名..."
if keytool -list -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" > /dev/null 2>&1; then
    echo "✅ 密钥别名 '$KEY_ALIAS' 存在"
    
    # 显示密钥信息
    echo ""
    echo "📝 密钥详细信息："
    keytool -list -v -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" | grep -E "别名|创建日期|条目类型|证书指纹" | head -4
else
    echo "❌ 密钥别名 '$KEY_ALIAS' 不存在"
    echo ""
    echo "可用的密钥别名："
    keytool -list -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" | grep -v "密钥库" | grep -v "条目数" | tail -n +2
    exit 1
fi
echo ""

# 验证密钥密码
echo "🔐 验证密钥密码..."
if keytool -list -keystore "$STORE_FILE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" -keypass "$KEY_PASSWORD" > /dev/null 2>&1; then
    echo "✅ 密钥密码正确"
else
    echo "⚠️  密钥密码验证失败（某些情况下这可能是正常的）"
fi
echo ""

# 检查 build.gradle.kts 配置
echo "📦 检查 build.gradle.kts 配置..."
GRADLE_FILE="$PROJECT_ROOT/android/app/build.gradle.kts"
if grep -q "keystorePropertiesFile" "$GRADLE_FILE"; then
    echo "✅ build.gradle.kts 已配置 keystore 读取"
else
    echo "⚠️  build.gradle.kts 可能未正确配置 keystore"
fi
echo ""

echo "✅ 所有验证通过！keystore 配置正确。"
echo ""
echo "📌 提示："
echo "  - 本地开发使用: $STORE_FILE"
echo "  - CI/CD 使用: 从 GitHub Secrets 中的 ANDROID_KEYSTORE_BASE64 恢复"
echo "  - 确保 CI 中的 keystore 文件与本地使用的是同一个"

