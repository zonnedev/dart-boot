/// Generates access tokens.
abstract class TokenGenerator {
  /// Generate a token for the given subject with optional roles and custom claims.
  String generate(String subject, {List<String> roles = const [], Map<String, dynamic> claims = const {}});
}

/// Generates refresh tokens.
abstract class RefreshTokenGenerator {
  /// Generate a refresh token for the given subject.
  String generate(String subject);
}
