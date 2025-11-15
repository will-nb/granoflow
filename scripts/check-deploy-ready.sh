#!/bin/bash
# 检查是否准备好自动部署到 Google Play

set -e

echo "🔍 检查 Google Play 自动部署准备情况..."
echo ""

# 检查工作流文件
echo "📋 1. 检查工作流配置..."
if [ -f ".github/workflows/release-android-alpha.yml" ]; then
    echo "   ✅ release-android-alpha.yml 存在"
else
    echo "   ❌ release-android-alpha.yml 不存在"
fi

if [ -f ".github/workflows/deploy-android.yml" ]; then
    echo "   ✅ deploy-android.yml 存在"
else
    echo "   ❌ deploy-android.yml 不存在"
fi
echo ""

# 检查本地 keystore 配置
echo "📋 2. 检查本地 keystore 配置..."
if [ -f "android/app/keystore.properties" ]; then
    echo "   ✅ keystore.properties 存在"
    if grep -q "storeFile=" android/app/keystore.properties; then
        STORE_FILE=$(grep "^storeFile=" android/app/keystore.properties | cut -d'=' -f2)
        if [ -f "$STORE_FILE" ]; then
            echo "   ✅ keystore 文件存在: $STORE_FILE"
        else
            echo "   ❌ keystore 文件不存在: $STORE_FILE"
        fi
    fi
else
    echo "   ❌ keystore.properties 不存在"
fi
echo ""

# 检查版本号
echo "📋 3. 检查版本号..."
if [ -f "pubspec.yaml" ]; then
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    if [ -n "$VERSION" ]; then
        echo "   ✅ 当前版本: $VERSION"
        VERSION_CODE=$(echo "$VERSION" | cut -d'+' -f2)
        if [ -n "$VERSION_CODE" ] && [ "$VERSION_CODE" -gt 0 ] 2>/dev/null; then
            echo "   ✅ versionCode: $VERSION_CODE"
        else
            echo "   ⚠️  versionCode 可能无效: $VERSION_CODE"
        fi
    else
        echo "   ❌ 无法读取版本号"
    fi
else
    echo "   ❌ pubspec.yaml 不存在"
fi
echo ""

# 列出需要的 GitHub Secrets
echo "📋 4. 需要配置的 GitHub Secrets："
echo ""
echo "   必须在 GitHub Repository Settings → Secrets and variables → Actions 中配置："
echo ""
echo "   ✅ ANDROID_KEYSTORE_BASE64"
echo "      - keystore 文件的 base64 编码"
echo "      - 执行: base64 -i /Users/will/.keystores/granoflow-upload-key.jks | pbcopy"
echo ""
echo "   ✅ ANDROID_KEYSTORE_PASSWORD"
echo "      - keystore 密码: 3LXXtaL2ztukJe3H"
echo ""
echo "   ✅ ANDROID_KEY_ALIAS"
echo "      - 密钥别名: granoflow"
echo ""
echo "   ✅ ANDROID_KEY_PASSWORD"
echo "      - 密钥密码: 3LXXtaL2ztukJe3H"
echo ""
echo "   ✅ GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
echo "      - Google Play Service Account 的完整 JSON 内容"
echo ""
echo "📋 5. Google Play Console 前置条件："
echo ""
echo "   ⚠️  需要确认："
echo "   - 应用是否已在 Google Play Console 创建？"
echo "   - 包名是否为 com.granoflow.lite？"
echo "   - Service Account 是否已授予发布权限？"
echo ""
echo "📋 6. 触发条件："
echo ""
echo "   当以下文件变更并推送到 develop 分支时，会自动触发："
echo "   - lib/**"
echo "   - android/**"
echo "   - pubspec.yaml"
echo "   - .github/workflows/release-android-alpha.yml"
echo ""
echo "   或者手动在 GitHub Actions 页面触发工作流"
echo ""

