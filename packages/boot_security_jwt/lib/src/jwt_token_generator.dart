import 'package:boot_core/boot_core.dart';
import 'package:boot_security/boot_security.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'jwt_config.dart';

part 'jwt_token_generator.g.dart';

/// JWT implementation of [TokenGenerator].
@Singleton()
class JwtTokenGenerator implements TokenGenerator {
  final JwtConfig _config;

  JwtTokenGenerator(this._config);

  @override
  String generate(String subject, {List<String> roles = const [], Map<String, dynamic> claims = const {}}) {
    final payload = <String, dynamic>{
      'sub': subject,
      'roles': roles,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ...claims,
    };
    if (_config.issuer != null) payload['iss'] = _config.issuer;

    final jwt = JWT(payload);
    return jwt.sign(SecretKey(_config.secret), expiresIn: _config.expirationDuration);
  }
}
