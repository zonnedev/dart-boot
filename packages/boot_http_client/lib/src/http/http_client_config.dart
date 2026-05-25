import 'package:boot_core/boot_core.dart';

part 'http_client_config.g.dart';

/// Global HTTP client configuration, bound from `boot.http.client.*`.
///
/// ```yaml
/// boot:
///   http:
///     client:
///       connect-timeout: 5s
///       read-timeout: 30s
///       max-redirects: 5
/// ```
@ConfigurationProperties('boot.http.client')
class HttpClientConfig {
  final Duration connectTimeout;
  final Duration readTimeout;
  final int maxRedirects;

  HttpClientConfig({
    this.connectTimeout = const Duration(seconds: 5),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
  });
}
