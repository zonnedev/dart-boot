import 'authentication.dart';
import 'authentication_request.dart';

/// Implement to provide authentication logic (e.g., validate JWT, check credentials).
/// Boot discovers all AuthenticationProvider beans and tries them in order.
abstract class AuthenticationProvider {
  /// Attempt to authenticate the request. Return an [Authentication] on success, null on failure.
  Future<Authentication?> authenticate(AuthenticationRequest request);
}
