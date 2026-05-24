import 'package:boot_core/boot_core.dart';

/// Configuration for the HTTP client, read from `boot.http.client.*` in application.yml.
///
/// ```yaml
/// boot:
///   http:
///     client:
///       connect-timeout: 5s
///       read-timeout: 30s
///       max-redirects: 5
/// ```
class HttpClientConfiguration {
  final Duration connectTimeout;
  final Duration readTimeout;
  final int maxRedirects;

  HttpClientConfiguration({
    this.connectTimeout = const Duration(seconds: 5),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
  });

  /// Create from BootConfig (reads boot.http.client.* properties).
  factory HttpClientConfiguration.fromConfig(BootConfig config) {
    return HttpClientConfiguration(
      connectTimeout: _parseDuration(config.get('boot.http.client.connect-timeout')) ?? const Duration(seconds: 5),
      readTimeout: _parseDuration(config.get('boot.http.client.read-timeout')) ?? const Duration(seconds: 30),
      maxRedirects: int.tryParse(config.get('boot.http.client.max-redirects') ?? '') ?? 5,
    );
  }

  static Duration? _parseDuration(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.endsWith('ms')) return Duration(milliseconds: int.parse(value.replaceAll('ms', '')));
    if (value.endsWith('s')) return Duration(seconds: int.parse(value.replaceAll('s', '')));
    if (value.endsWith('m')) return Duration(minutes: int.parse(value.replaceAll('m', '')));
    return null;
  }
}
