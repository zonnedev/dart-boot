import 'package:boot_core/boot_core.dart';

/// CORS configuration, read from `boot.http.cors.*` in application.yml.
///
/// ```yaml
/// boot:
///   http:
///     cors:
///       enabled: true
///       allowed-origins:
///         - https://example.com
///       allowed-methods:
///         - GET
///         - POST
///         - PUT
///         - DELETE
///       allowed-headers:
///         - Content-Type
///         - Authorization
///       exposed-headers:
///         - X-Request-Id
///       allow-credentials: true
///       max-age: 3600
/// ```
class CorsConfiguration {
  final bool enabled;
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final List<String> exposedHeaders;
  final bool allowCredentials;
  final int maxAge;

  CorsConfiguration({
    this.enabled = false,
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    this.allowedHeaders = const ['Content-Type', 'Authorization'],
    this.exposedHeaders = const [],
    this.allowCredentials = false,
    this.maxAge = 3600,
  });

  factory CorsConfiguration.fromConfig(BootConfig config) {
    final enabled = config.get('boot.http.cors.enabled') == 'true';
    if (!enabled) return CorsConfiguration();

    return CorsConfiguration(
      enabled: true,
      allowedOrigins: _getList(config, 'boot.http.cors.allowed-origins') ?? ['*'],
      allowedMethods: _getList(config, 'boot.http.cors.allowed-methods') ??
          ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: _getList(config, 'boot.http.cors.allowed-headers') ??
          ['Content-Type', 'Authorization'],
      exposedHeaders: _getList(config, 'boot.http.cors.exposed-headers') ?? [],
      allowCredentials: config.get('boot.http.cors.allow-credentials') == 'true',
      maxAge: int.tryParse(config.get('boot.http.cors.max-age') ?? '') ?? 3600,
    );
  }

  static List<String>? _getList(BootConfig config, String key) {
    final items = <String>[];
    for (var i = 0; i < 20; i++) {
      final val = config.get('$key[$i]');
      if (val == null) break;
      items.add(val);
    }
    return items.isEmpty ? null : items;
  }

  bool isOriginAllowed(String origin) {
    if (allowedOrigins.contains('*')) return true;
    return allowedOrigins.contains(origin);
  }
}
