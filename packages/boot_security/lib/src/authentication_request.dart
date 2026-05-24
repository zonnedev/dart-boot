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
