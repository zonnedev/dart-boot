import 'package:boot/boot.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

part 'jwt_service.g.dart';

@Singleton()
class JwtService {
  final String _secret;

  JwtService(@Value('\${auth.jwt.secret:boot-secret-change-me}') this._secret);

  String createToken(String username, List<String> roles) {
    final jwt = JWT({'sub': username, 'roles': roles});
    return jwt.sign(SecretKey(_secret), expiresIn: Duration(hours: 24));
  }

  Map<String, dynamic>? verify(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      return jwt.payload as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
