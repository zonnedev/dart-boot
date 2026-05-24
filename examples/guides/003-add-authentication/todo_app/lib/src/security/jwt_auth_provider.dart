import 'package:boot/boot.dart';
import '../services/jwt_service.dart';

part 'jwt_auth_provider.g.dart';

@Singleton()
class JwtAuthProvider implements AuthenticationProvider {
  final JwtService _jwt;

  JwtAuthProvider(this._jwt);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final header = request.authorization;
    if (header == null || !header.startsWith('Bearer ')) return null;

    final token = header.substring(7);
    final claims = _jwt.verify(token);
    if (claims == null) return null;

    return Authentication(
      name: claims['sub'] as String,
      roles: List<String>.from(claims['roles'] ?? []),
    );
  }
}
