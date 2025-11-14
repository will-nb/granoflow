/// Central definition of configuration key names. These constants must align
/// with the entries documented in `config.yaml`.
class ConfigKeys {
  const ConfigKeys._();

  static const String environment = 'GRANOFLOW_ENV';
  static const String apiBaseUrl = 'GRANOFLOW_API_BASE_URL';
  static const String websocketUrl = 'GRANOFLOW_WEBSOCKET_URL';
  static const String isarDirectory = 'GRANOFLOW_ISAR_DIR';
  static const String featureFocusTimer = 'GRANOFLOW_FEATURE_FOCUS_TIMER';
  static const String featureMonetization = 'GRANOFLOW_FEATURE_MONETIZATION';
  static const String sentryDsn = 'GRANOFLOW_SENTRY_DSN';
  
  // 应用版本类型配置
  static const String appEdition = 'GRANOFLOW_APP_EDITION'; // 'lite' 或 'pro'
  static const String packageName = 'GRANOFLOW_PACKAGE_NAME'; // 用于动态设置包名
}
