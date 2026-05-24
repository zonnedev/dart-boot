import 'package:boot_core/boot_core.dart';
import 'package:boot_security/boot_security.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'jwt_config.dart';

part 'jwt_refresh_token_generator.g.dart';

/// JWT implementation of [RefreshTokenGenerator].
@Singleton()
class JwtRefreshTokenGenerator implements RefreshTokenGenerator {
  final JwtConfig _config;

  JwtRefreshTokenGenerator(this._config);

  @override
  String generate(String subject) {
    final payload = <String, dynamic>{
      'sub': subject,
      'type': 'refresh',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    if (_config.issuer != null) payload['iss'] = _config.issuer;

    final jwt = JWT(payload);
    return jwt.sign(SecretKey(_config.secret), expiresIn: _config.refreshExpirationDuration);
  }
}
