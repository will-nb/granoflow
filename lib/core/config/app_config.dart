import 'package:flutter/foundation.dart';

import 'config_keys.dart';

/// Supported deployment environments.
enum AppEnvironment { development, staging, production }

/// Immutable snapshot of runtime configuration sourced from environment
/// variables or build-time `--dart-define` flags.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    this.apiBaseUrl,
    this.websocketUrl,
    this.isarDirectory,
    required this.featureFocusTimer,
    required this.featureMonetization,
    this.sentryDsn,
  });

  final AppEnvironment environment;
  final Uri? apiBaseUrl;
  final Uri? websocketUrl;
  final String? isarDirectory;
  final bool featureFocusTimer;
  final bool featureMonetization;
  final Uri? sentryDsn;

  bool get isProduction => environment == AppEnvironment.production;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isDevelopment => environment == AppEnvironment.development;

  /// Construct configuration from compile-time environment values.
  ///
  /// [overrides] can be supplied by tests to simulate specific environments.
  factory AppConfig.fromEnvironment({Map<String, String>? overrides}) {
    final source = _ConfigSource(overrides: overrides);

    final environment = _parseEnvironment(source.read(ConfigKeys.environment) ?? 'development');
    final apiBaseUrl = _parseUri(
      source.read(ConfigKeys.apiBaseUrl),
      name: ConfigKeys.apiBaseUrl,
      required: false,
    );
    final websocketUrl = _parseUri(
      source.read(ConfigKeys.websocketUrl),
      name: ConfigKeys.websocketUrl,
      required: false,
    );

    final isarDir = source.read(ConfigKeys.isarDirectory);
    final featureFocusTimer = _parseBool(
      source.read(ConfigKeys.featureFocusTimer),
      defaultValue: true,
    );
    final featureMonetization = _parseBool(
      source.read(ConfigKeys.featureMonetization),
      defaultValue: false,
    );
    final sentryDsn = _parseUri(
      source.read(ConfigKeys.sentryDsn),
      name: ConfigKeys.sentryDsn,
      required: false,
    );

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      websocketUrl: websocketUrl,
      isarDirectory: isarDir?.isEmpty == true ? null : isarDir,
      featureFocusTimer: featureFocusTimer,
      featureMonetization: featureMonetization,
      sentryDsn: sentryDsn,
    );
  }
}

class _ConfigSource {
  _ConfigSource({Map<String, String>? overrides}) {
    if (overrides != null) {
      _values.addAll(overrides);
    }
  }

  final Map<String, String> _values = <String, String>{};

  String? read(String key) {
    if (_values.containsKey(key)) {
      return _values[key];
    }
    final compileTimeValue = String.fromEnvironment(key);
    if (compileTimeValue.isNotEmpty) {
      return compileTimeValue;
    }
    return null;
  }
}

AppEnvironment _parseEnvironment(String value) {
  switch (value.toLowerCase()) {
    case 'production':
    case 'prod':
      return AppEnvironment.production;
    case 'staging':
    case 'stage':
      return AppEnvironment.staging;
    default:
      return AppEnvironment.development;
  }
}


Uri? _parseUri(String? value, {required String name, bool required = true}) {
  if (value == null || value.isEmpty) {
    if (required) {
      throw StateError('Missing configuration value for $name');
    }
    return null;
  }
  final parsed = Uri.tryParse(value);
  if (parsed == null || (!parsed.hasScheme && required)) {
    throw StateError('Invalid URI for $name: $value');
  }
  return parsed;
}

bool _parseBool(String? value, {required bool defaultValue}) {
  if (value == null) {
    return defaultValue;
  }
  final lower = value.toLowerCase();
  if (lower == 'true' || lower == '1' || lower == 'yes') {
    return true;
  }
  if (lower == 'false' || lower == '0' || lower == 'no') {
    return false;
  }
  return defaultValue;
}
