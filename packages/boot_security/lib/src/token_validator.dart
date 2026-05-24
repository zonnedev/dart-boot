/// Validates a token and returns its claims.
///
/// Returns null if the token is invalid, expired, or cannot be verified.
abstract class TokenValidator {
  /// Validate the token. Returns claims map on success, null on failure.
  Map<String, dynamic>? validate(String token);
}
