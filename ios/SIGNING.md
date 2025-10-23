# iOS Signing Setup

1. 在 Xcode 中打开 `ios/Runner.xcworkspace`，切换到 `Runner` target。
2. 在 `Signing & Capabilities` 中勾选 `Automatically manage signing`，选择对应的 Team。
3. 为 Release 配置独立的 Provisioning Profile，确保 Bundle Identifier 与证书一致。
4. 将 `.p12` 和 `.mobileprovision` 保存到安全存储，并在 CI 中以环境变量或配置文件方式注入。

项目默认使用 Debug 配置方便开发，提交 Release 包时请切换到 `Runner (Release)` 方案并确认签名无误。
