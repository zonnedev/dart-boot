import 'package:boot_core/boot_core.dart';

/// Per-service HTTP client configuration, auto-registered from YAML.
///
/// ```yaml
/// boot:
///   http:
///     client:
///       services:
///         github:
///           url: https://api.github.com
///           connect-timeout: 10s
///           read-timeout: 30s
///           max-redirects: 5
/// ```
///
/// Produces one `@Named('github') HttpClientServiceConfig` bean per entry.
@EachProperty('boot.http.client.services')
class HttpClientServiceConfig {
  final String url;
  final Duration connectTimeout;
  final Duration readTimeout;
  final int maxRedirects;

  HttpClientServiceConfig({
    this.url = '',
    this.connectTimeout = const Duration(seconds: 5),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
  });
}
