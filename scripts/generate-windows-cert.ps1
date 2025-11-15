# 生成 Windows MSIX 测试用自签名证书
# 适用于 Windows PowerShell

$ErrorActionPreference = "Stop"

$CertDir = "windows"
$CertName = "granoflow-test-cert"
$CertPath = Join-Path $CertDir "$CertName.pfx"
$Password = "TestPassword123"
$SecurePassword = ConvertTo-SecureString -String $Password -Force -AsPlainText

Write-Host "🔐 生成 Windows MSIX 测试证书..." -ForegroundColor Cyan

# 创建证书目录
if (-not (Test-Path $CertDir)) {
    New-Item -ItemType Directory -Path $CertDir | Out-Null
}

# 生成自签名证书（有效期 10 年）
Write-Host "📝 生成自签名证书（有效期 10 年）..." -ForegroundColor Yellow

$Cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=GranoFlow Test Publisher, O=GranoFlow, C=CN" `
    -KeyUsage DigitalSignature `
    -FriendlyName "GranoFlow Test Certificate" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}") `
    -NotAfter (Get-Date).AddYears(10)

# 导出为 PFX 文件
Write-Host "📦 导出为 PFX 格式..." -ForegroundColor Yellow

Export-PfxCertificate `
    -Cert $Cert `
    -FilePath $CertPath `
    -Password $SecurePassword | Out-Null

# 从证书存储中删除（可选，证书已导出到文件）
# Remove-Item "Cert:\CurrentUser\My\$($Cert.Thumbprint)"

Write-Host "✅ 证书生成成功！" -ForegroundColor Green
Write-Host "📁 证书位置: $CertPath" -ForegroundColor Cyan
Write-Host "🔑 证书密码: $Password" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  注意: 此证书仅用于本地测试，不能用于正式发布" -ForegroundColor Yellow
Write-Host "📖 使用说明请查看: windows/MSIX_TESTING.md" -ForegroundColor Cyan

