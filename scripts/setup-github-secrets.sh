#!/bin/bash
# 生成 GitHub Secrets 配置信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEYSTORE_FILE="/Users/will/.keystores/granoflow-upload-key.jks"
TEMP_DIR="$PROJECT_ROOT/temp"

echo "🔐 生成 GitHub Secrets 配置信息..."
echo ""

# 创建 temp 目录
mkdir -p "$TEMP_DIR"

# 生成 base64 编码
echo "📦 生成 keystore base64 编码..."
if [ -f "$KEYSTORE_FILE" ]; then
    base64 -i "$KEYSTORE_FILE" > "$TEMP_DIR/keystore-base64.txt"
    BASE64_SIZE=$(wc -c < "$TEMP_DIR/keystore-base64.txt" | tr -d ' ')
    echo "   ✅ Base64 编码已生成: $TEMP_DIR/keystore-base64.txt ($BASE64_SIZE 字符)"
else
    echo "   ❌ Keystore 文件不存在: $KEYSTORE_FILE"
    exit 1
fi
echo ""

# 读取配置
if [ -f "$PROJECT_ROOT/android/app/keystore.properties" ]; then
    STORE_PASSWORD=$(grep "^storePassword=" "$PROJECT_ROOT/android/app/keystore.properties" | cut -d'=' -f2)
    KEY_ALIAS=$(grep "^keyAlias=" "$PROJECT_ROOT/android/app/keystore.properties" | cut -d'=' -f2)
    KEY_PASSWORD=$(grep "^keyPassword=" "$PROJECT_ROOT/android/app/keystore.properties" | cut -d'=' -f2)
else
    echo "❌ keystore.properties 文件不存在"
    exit 1
fi

# 生成配置文档
echo "📝 生成配置文档..."
cat > "$TEMP_DIR/github-secrets-values.txt" << EOF
# GitHub Secrets 配置值
# 请复制以下值到 GitHub Repository Settings → Secrets and variables → Actions

========================================
1. ANDROID_KEYSTORE_BASE64
========================================
（完整内容见: $TEMP_DIR/keystore-base64.txt）
文件大小: $BASE64_SIZE 字符

========================================
2. ANDROID_KEYSTORE_PASSWORD
========================================
$STORE_PASSWORD

========================================
3. ANDROID_KEY_ALIAS
========================================
$KEY_ALIAS

========================================
4. ANDROID_KEY_PASSWORD
========================================
$KEY_PASSWORD

========================================
5. GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
========================================
（需要你手动添加 Service Account JSON 文件内容）

========================================
配置步骤：
========================================
1. 访问: https://github.com/YOUR_USERNAME/granoflow/settings/secrets/actions
   （替换 YOUR_USERNAME 为你的 GitHub 用户名）

2. 点击 "New repository secret"

3. 依次创建以上 5 个 secrets：
   - Name: ANDROID_KEYSTORE_BASE64
     Value: 复制 $TEMP_DIR/keystore-base64.txt 的完整内容
   
   - Name: ANDROID_KEYSTORE_PASSWORD
     Value: $STORE_PASSWORD
   
   - Name: ANDROID_KEY_ALIAS
     Value: $KEY_ALIAS
   
   - Name: ANDROID_KEY_PASSWORD
     Value: $KEY_PASSWORD
   
   - Name: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
     Value: 你下载的 Service Account JSON 文件完整内容

4. 配置完成后，推送到 develop 分支即可自动触发部署

EOF

echo "   ✅ 配置值已保存到: $TEMP_DIR/github-secrets-values.txt"
echo ""

# 显示配置信息
echo "📋 GitHub Secrets 配置值："
echo ""
echo "1. ANDROID_KEYSTORE_BASE64"
echo "   文件: $TEMP_DIR/keystore-base64.txt"
echo "   大小: $BASE64_SIZE 字符"
echo ""
echo "2. ANDROID_KEYSTORE_PASSWORD"
echo "   值: $STORE_PASSWORD"
echo ""
echo "3. ANDROID_KEY_ALIAS"
echo "   值: $KEY_ALIAS"
echo ""
echo "4. ANDROID_KEY_PASSWORD"
echo "   值: $KEY_PASSWORD"
echo ""
echo "5. GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
echo "   （需要你手动添加）"
echo ""
echo "✅ 所有配置信息已准备完成！"
echo ""
echo "📌 下一步："
echo "   1. 查看详细配置: cat $TEMP_DIR/github-secrets-values.txt"
echo "   2. 复制 base64 内容: cat $TEMP_DIR/keystore-base64.txt | pbcopy"
echo "   3. 访问 GitHub Secrets 页面配置"
echo ""

