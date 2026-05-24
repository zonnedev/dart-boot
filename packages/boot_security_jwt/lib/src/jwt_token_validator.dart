import 'package:boot_core/boot_core.dart';
import 'package:boot_security/boot_security.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'jwt_config.dart';

part 'jwt_token_validator.g.dart';

/// JWT implementation of [TokenValidator].
@Singleton()
class JwtTokenValidator implements TokenValidator {
  final JwtConfig _config;

  JwtTokenValidator(this._config);

  @override
  Map<String, dynamic>? validate(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_config.secret));
      final payload = jwt.payload as Map<String, dynamic>;
      if (_config.issuer != null && payload['iss'] != _config.issuer) return null;
      return payload;
    } catch (_) {
      return null;
    }
  }
}
