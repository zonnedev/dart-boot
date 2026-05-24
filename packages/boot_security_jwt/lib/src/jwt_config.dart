import 'package:boot_core/boot_core.dart';

part 'jwt_config.g.dart';

/// Configuration for JWT token handling.
///
/// Reads from `application.yml`:
/// ```yaml
/// boot:
///   security:
///     jwt:
///       secret: my-secret-key
///       expiration: 1h
///       refresh-expiration: 7d
///       issuer: my-app
/// ```
@Singleton()
class JwtConfig {
  /// Secret key for HMAC signing.
  final String secret;

  /// Access token expiration duration string (e.g., "1h", "30m").
  final String expiration;

  /// Refresh token expiration duration string (e.g., "7d").
  final String refreshExpiration;

  /// Token issuer (iss claim). If set, tokens without matching issuer are rejected.
  final String? issuer;

  JwtConfig(
    @Value('\${boot.security.jwt.secret}') this.secret,
    @Value('\${boot.security.jwt.expiration:1h}') this.expiration,
    @Value('\${boot.security.jwt.refresh-expiration:7d}') this.refreshExpiration,
    @Value('\${boot.security.jwt.issuer:}') String issuer,
  ) : issuer = issuer.isEmpty ? null : issuer;

  /// Parsed access token expiration.
  Duration get expirationDuration => _parse(expiration);

  /// Parsed refresh token expiration.
  Duration get refreshExpirationDuration => _parse(refreshExpiration);

  static Duration _parse(String value) {
    final v = value.trim();
    if (v.endsWith('ms')) return Duration(milliseconds: int.parse(v.substring(0, v.length - 2)));
    if (v.endsWith('s')) return Duration(seconds: int.parse(v.substring(0, v.length - 1)));
    if (v.endsWith('m')) return Duration(minutes: int.parse(v.substring(0, v.length - 1)));
    if (v.endsWith('h')) return Duration(hours: int.parse(v.substring(0, v.length - 1)));
    if (v.endsWith('d')) return Duration(days: int.parse(v.substring(0, v.length - 1)));
    throw FormatException('Invalid duration format: $value');
  }
}
