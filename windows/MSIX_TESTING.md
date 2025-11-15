# MSIX 包生成和测试指南

本指南介绍如何在注册 Microsoft Store 账号之前，使用自签名证书生成和测试 MSIX 包。

## 前置要求

- Flutter SDK 已安装
- Windows 10/11 系统（用于测试 MSIX 包）
- OpenSSL（macOS/Linux）或 PowerShell（Windows）

## 步骤 1: 生成自签名证书

### macOS/Linux

```bash
# 运行证书生成脚本
./scripts/generate-windows-cert.sh
```

### Windows

```powershell
# 在 PowerShell 中运行
.\scripts\generate-windows-cert.ps1
```

证书将生成在 `windows/granoflow-test-cert.pfx`，密码为 `uKcaZRFLezfR68aW`。

## 步骤 2: 安装依赖

```bash
flutter pub get
```

## 步骤 3: 生成 MSIX 包

```bash
flutter pub run msix:create
```

生成的 MSIX 文件位于：`build/windows/runner/Release/*.msix`

## 步骤 4: 安装证书到 Windows 系统（重要）

在 Windows 上安装 MSIX 包之前，必须先安装自签名证书到系统。

### 方法 1: 通过证书文件安装

1. 将 `windows/granoflow-test-cert.pfx` 复制到 Windows 系统
2. 右键点击 `.pfx` 文件，选择"安装 PFX"
3. 选择"本地计算机"
4. 输入密码：`uKcaZRFLezfR68aW`
5. 选择"将所有证书放入以下存储"
6. 浏览并选择"受信任的根证书颁发机构"
7. 完成安装

### 方法 2: 通过 MSIX 文件安装

1. 右键点击生成的 `.msix` 文件
2. 选择"属性" → "数字签名" 选项卡
3. 选择签名，点击"详细信息"
4. 点击"查看证书"
5. 点击"安装证书"
6. 选择"本地计算机"
7. 选择"将所有证书放入以下存储"
8. 浏览并选择"受信任的根证书颁发机构"
9. 完成安装

### 方法 3: 使用 PowerShell（管理员权限）

```powershell
# 导入证书到受信任的根证书颁发机构
$password = ConvertTo-SecureString -String "uKcaZRFLezfR68aW" -Force -AsPlainText
Import-PfxCertificate `
    -FilePath "windows/granoflow-test-cert.pfx" `
    -CertStoreLocation "Cert:\LocalMachine\Root" `
    -Password $password
```

## 步骤 5: 安装 MSIX 包

### 方法 1: 双击安装

直接双击 `.msix` 文件，Windows 会自动安装。

### 方法 2: 使用 PowerShell

```powershell
Add-AppxPackage -Path "build/windows/runner/Release/granoflow_1.0.0.0_x64.msix"
```

## 步骤 6: 测试应用

1. 在开始菜单中找到 "GranoFlow"
2. 启动应用并测试功能
3. 验证所有功能正常工作

## 步骤 7: 卸载测试包

```powershell
# 查看已安装的包
Get-AppxPackage | Where-Object {$_.Name -like "*granoflow*"}

# 卸载（替换为实际的包名）
Remove-AppxPackage -Package "包的全名"
```

## 配置说明

### pubspec.yaml 中的 msix_config

当前配置使用测试证书：

```yaml
msix_config:
  display_name: "GranoFlow"
  publisher_display_name: "GranoFlow Team"
  identity_name: "com.granoflow.lite"
  publisher: "CN=GranoFlow Test Publisher"
  msix_version: 1.0.0.0
  certificate_path: "windows/granoflow-test-cert.pfx"
  certificate_password: "uKcaZRFLezfR68aW"
  start_menu: true
  desktop_shortcut: true
  architecture: x64
```

## 注册 Microsoft Store 后的更新

注册 Microsoft Partner Center 后，需要更新配置：

1. **获取应用标识信息**
   - 在 Partner Center 中获取 `identity_name` 和 `publisher`
   - 这些信息必须与 Partner Center 中的完全一致

2. **更新 pubspec.yaml**
   ```yaml
   msix_config:
     display_name: "GranoFlow"
     publisher_display_name: "你的发布者显示名称"
     identity_name: "com.granoflow.lite"  # 从 Partner Center 获取
     publisher: "CN=你的真实发布者名称"  # 从 Partner Center 获取
     msix_version: 1.0.0.0
     # 移除证书配置（Microsoft 会自动签名）
     # certificate_path: ...  # 删除
     # certificate_password: ...  # 删除
     start_menu: true
     desktop_shortcut: true
     architecture: x64
   ```

3. **重新生成 MSIX 包**
   ```bash
   flutter pub run msix:create
   ```

4. **提交到 Microsoft Store**
   - 在 Partner Center 创建新的应用提交
   - 上传 MSIX 包
   - 填写应用信息并提交审核

## 常见问题

### Q: 安装 MSIX 时提示"无法安装此应用包"
A: 确保已正确安装自签名证书到"受信任的根证书颁发机构"。

### Q: 证书安装后仍然无法安装 MSIX
A: 尝试重启计算机，或使用 PowerShell 以管理员权限安装证书。

### Q: 如何更新版本号？
A: 修改 `pubspec.yaml` 中的 `msix_version`，格式为 `major.minor.build.revision`（如 `1.0.1.0`）。

### Q: 可以修改证书密码吗？
A: 可以，但需要同时更新 `pubspec.yaml` 中的 `certificate_password` 和证书生成脚本中的密码。

## 注意事项

- ⚠️ 测试证书仅用于本地测试，不能用于正式发布
- ⚠️ 证书文件（.pfx）已通过 .gitignore 排除，不会提交到仓库
- ⚠️ MSIX 包只能在 Windows 10/11 上安装和运行
- ⚠️ 首次提交到 Microsoft Store 需要手动完成，后续可以使用 API 自动化

## 参考资源

- [Flutter Windows 部署文档](https://docs.flutter.dev/deployment/windows)
- [MSIX 打包工具文档](https://learn.microsoft.com/zh-cn/windows/msix/)
- [Microsoft Partner Center](https://partner.microsoft.com/)

