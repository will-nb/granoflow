# macOS Signing Setup

## Staging 环境（当前）

Staging 环境使用 **ad-hoc 签名**（临时签名），不需要 Apple Developer 证书。这意味着：

- ✅ 应用可以正常构建和打包
- ⚠️ 首次打开时会显示"无法验证开发者"的警告
- ✅ 用户可以绕过：**右键点击 DMG 中的应用 → 选择"打开"**，然后在弹出的对话框中选择"打开"

### 安装步骤

1. 下载 DMG 文件
2. 双击挂载 DMG
3. 如果出现"无法打开，因为无法验证开发者"：
   - **方法 1（推荐）**：右键点击应用图标 → 选择"打开" → 在对话框中选择"打开"
   - **方法 2**：打开"系统设置" → "隐私与安全性" → 找到被阻止的应用 → 点击"仍要打开"
4. 将应用拖拽到 Applications 文件夹

## Production 环境（未来）

正式发布需要 Apple Developer 证书：

1. 打开 `macos/Runner.xcworkspace`，在 `Runner` target 的 `Signing & Capabilities` 中选择开发者证书。
2. 为 Release 构建指定 `Developer ID Application` 证书，Debug 构建可使用 `Apple Development`。
3. 若需发布到 App Store Connect，请创建对应的 `App Store` profile 并在 CI 中写入。
4. 通过 `xcodebuild -exportArchive` 时提供 `exportOptions.plist`，其中包含签名与 notarization 配置。

未配置证书时，工程将使用 `Sign to Run Locally` 方案以便调试；发布前务必替换为正式签名。
