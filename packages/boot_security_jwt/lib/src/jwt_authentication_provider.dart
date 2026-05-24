import 'package:boot_core/boot_core.dart';
import 'package:boot_security/boot_security.dart';

part 'jwt_authentication_provider.g.dart';

/// AuthenticationProvider that uses [TokenReader] to extract a token
/// and [TokenValidator] to verify it.
///
/// Composes the two interfaces — swap either independently via `@Replaces`.
@Singleton()
class JwtAuthenticationProvider implements AuthenticationProvider {
  final TokenReader _reader;
  final TokenValidator _validator;

  JwtAuthenticationProvider(this._reader, this._validator);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final token = _reader.read(request);
    if (token == null) return null;

    final claims = _validator.validate(token);
    if (claims == null) return null;

    return Authentication(
      name: claims['sub'] as String? ?? '',
      roles: List<String>.from(claims['roles'] ?? []),
      attributes: claims,
    );
  }
}
