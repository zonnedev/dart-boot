import 'authentication_request.dart';

/// Extracts a token string from an authentication request.
///
/// Default implementation: [BearerTokenReader] (reads Authorization: Bearer <token>).
/// Replace to read from cookies, query params, or custom headers.
abstract class TokenReader {
  /// Extract the token from the request, or null if not present.
  String? read(AuthenticationRequest request);
}
