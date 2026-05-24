/// Represents an authenticated user.
class Authentication {
  final String name;
  final List<String> roles;
  final Map<String, dynamic> attributes;

  Authentication({required this.name, this.roles = const [], this.attributes = const {}});
}

/// Implement to provide authentication logic (e.g., validate JWT, check credentials).
/// Boot discovers all AuthenticationProvider beans and tries them in order.
abstract class AuthenticationProvider {
  /// Attempt to authenticate the request. Return an [Authentication] on success, null on failure.
  Future<Authentication?> authenticate(AuthenticationRequest request);
}

/// The authentication request — carries all connection context for credential extraction.
/// Works for HTTP, WebSocket, mTLS — providers check what's available.
class AuthenticationRequest {
  /// The raw Authorization header value (e.g., "Bearer <token>").
  final String? authorization;

  /// All request headers.
  final Map<String, String> headers;

  /// Query parameters (useful for WebSocket token auth).
  final Map<String, String> queryParams;

  /// The request path.
  final String path;

  /// The HTTP method.
  final String method;

  /// Client X.509 certificates from mTLS (null if not TLS or no client cert).
  final List<dynamic>? clientCertificates;

  /// Whether the connection is over TLS.
  final bool isTls;

  /// Remote address of the client.
  final String? remoteAddress;

  AuthenticationRequest({
    this.authorization,
    this.headers = const {},
    this.queryParams = const {},
    this.path = '',
    this.method = '',
    this.clientCertificates,
    this.isTls = false,
    this.remoteAddress,
  });
}

/// Constants for @Secured annotation values.
class SecurityRule {
  static const String isAuthenticated = 'isAuthenticated()';
  static const String isAnonymous = 'isAnonymous()';
  static const String denyAll = 'denyAll()';

  SecurityRule._();
}

/// Marks a controller or method with access rules.
///
/// ```dart
/// @Controller('/admin')
/// @Secured([SecurityRule.isAuthenticated])
/// class AdminController { ... }
///
/// @Get('/public')
/// @Secured([SecurityRule.isAnonymous])
/// Future<Response> publicEndpoint(Request req) async { ... }
///
/// @Get('/manage')
/// @Secured(['ROLE_ADMIN'])
/// Future<Response> adminOnly(Request req) async { ... }
/// ```
class Secured {
  final List<String> value;
  const Secured(this.value);
}
