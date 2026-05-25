/// Marks a class as a config-driven multi-instance bean.
///
/// For each sub-key under [prefix] in the configuration, one named bean
/// instance is created with fields populated from the config values.
///
/// ```dart
/// @EachProperty('boot.http.services')
/// class HttpServiceConfig {
///   final String url;
///   final Duration connectTimeout;
///   final int maxRedirects;
///   HttpServiceConfig({this.url = '', this.connectTimeout = const Duration(seconds: 5), this.maxRedirects = 5});
/// }
/// ```
///
/// With config:
/// ```yaml
/// boot:
///   http:
///     services:
///       github:
///         url: https://api.github.com
///         connect-timeout: 10s
///       stripe:
///         url: https://api.stripe.com
/// ```
///
/// Produces:
/// - `@Named('github') HttpServiceConfig` with url=https://api.github.com, connectTimeout=10s
/// - `@Named('stripe') HttpServiceConfig` with url=https://api.stripe.com, connectTimeout=5s (default)
///
/// Field names are converted from camelCase to kebab-case for config lookup.
class EachProperty {
  /// The config prefix to scan for sub-keys.
  final String prefix;

  const EachProperty(this.prefix);
}
