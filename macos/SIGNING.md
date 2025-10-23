# macOS Signing Setup

1. 打开 `macos/Runner.xcworkspace`，在 `Runner` target 的 `Signing & Capabilities` 中选择开发者证书。
2. 为 Release 构建指定 `Developer ID Application` 证书，Debug 构建可使用 `Apple Development`。
3. 若需发布到 App Store Connect，请创建对应的 `App Store` profile 并在 CI 中写入。
4. 通过 `xcodebuild -exportArchive` 时提供 `exportOptions.plist`，其中包含签名与 notarization 配置。

未配置证书时，工程将使用 `Sign to Run Locally` 方案以便调试；发布前务必替换为正式签名。
