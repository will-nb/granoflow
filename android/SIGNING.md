# Android Signing Setup

1. 复制 `app/keystore.sample.properties` 为 `app/keystore.properties`，填写实际路径与口令。
2. 将 Android Studio 中的 `Build Variants` 切换到 `release`，确保 Gradle 能够读取属性文件。
3. 在本地保存 `.jks` 文件，路径不纳入版本控制，建议放置在 `~/.keystores`。
4. CI/CD 发布前，将签名密钥注入为环境变量或安全存储，避免直接提交仓库。

Gradle 构建脚本会在存在 `keystore.properties` 时自动配置签名，若缺少则 fallback 到调试签名以支持本地开发。
