#!/bin/bash
# 生成 Windows MSIX 测试用自签名证书
# 适用于 macOS 和 Linux

set -e

CERT_DIR="windows"
CERT_NAME="granoflow-test-cert"
CERT_PATH="${CERT_DIR}/${CERT_NAME}.pfx"
PASSWORD="TestPassword123"

echo "🔐 生成 Windows MSIX 测试证书..."

# 检查 OpenSSL 是否安装
if ! command -v openssl &> /dev/null; then
    echo "❌ 错误: 未找到 OpenSSL"
    echo "请先安装 OpenSSL:"
    echo "  macOS: brew install openssl"
    echo "  Linux: sudo apt-get install openssl"
    exit 1
fi

# 创建证书目录
mkdir -p "${CERT_DIR}"

# 生成私钥
echo "📝 生成私钥..."
openssl genrsa -out "${CERT_DIR}/${CERT_NAME}-key.pem" 2048

# 创建证书签名请求
echo "📝 创建证书签名请求..."
openssl req -new -key "${CERT_DIR}/${CERT_NAME}-key.pem" \
    -out "${CERT_DIR}/${CERT_NAME}.csr" \
    -subj "/CN=GranoFlow Test Publisher/O=GranoFlow/C=CN"

# 生成自签名证书（有效期 10 年）
echo "📝 生成自签名证书（有效期 10 年）..."
openssl x509 -req -days 3650 \
    -in "${CERT_DIR}/${CERT_NAME}.csr" \
    -signkey "${CERT_DIR}/${CERT_NAME}-key.pem" \
    -out "${CERT_DIR}/${CERT_NAME}.crt" \
    -extensions v3_req \
    -extfile <(cat <<EOF
[v3_req]
keyUsage = digitalSignature
extendedKeyUsage = codeSigning
EOF
)

# 转换为 PFX 格式（Windows 需要）
echo "📦 转换为 PFX 格式..."
openssl pkcs12 -export \
    -out "${CERT_PATH}" \
    -inkey "${CERT_DIR}/${CERT_NAME}-key.pem" \
    -in "${CERT_DIR}/${CERT_NAME}.crt" \
    -name "GranoFlow Test Publisher" \
    -password "pass:${PASSWORD}"

# 清理临时文件
rm -f "${CERT_DIR}/${CERT_NAME}-key.pem" \
      "${CERT_DIR}/${CERT_NAME}.csr" \
      "${CERT_DIR}/${CERT_NAME}.crt"

echo "✅ 证书生成成功！"
echo "📁 证书位置: ${CERT_PATH}"
echo "🔑 证书密码: ${PASSWORD}"
echo ""
echo "⚠️  注意: 此证书仅用于本地测试，不能用于正式发布"
echo "📖 使用说明请查看: windows/MSIX_TESTING.md"

