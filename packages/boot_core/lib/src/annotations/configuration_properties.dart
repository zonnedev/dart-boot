import 'bean_source.dart';

/// Marks a class as a configuration-bound singleton bean.
///
/// Constructor parameters are automatically bound from application config
/// using the [prefix] + kebab-case parameter name.
///
/// ```dart
/// @ConfigurationProperties('boot.http.client')
/// class HttpClientConfig {
///   final Duration connectTimeout;
///   final Duration readTimeout;
///   final int maxRedirects;
///   HttpClientConfig({
///     this.connectTimeout = const Duration(seconds: 5),
///     this.readTimeout = const Duration(seconds: 30),
///     this.maxRedirects = 5,
///   });
/// }
/// ```
///
/// The above binds from:
/// - `boot.http.client.connect-timeout`
/// - `boot.http.client.read-timeout`
/// - `boot.http.client.max-redirects`
@BeanSource()
class ConfigurationProperties {
  /// The config prefix to bind from.
  final String prefix;

  const ConfigurationProperties(this.prefix);
}
