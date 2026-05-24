import 'package:boot/boot.dart';
import 'package:boot_security_jwt/boot_security_jwt.dart';

part 'auth_controller.g.dart';

@Controller('/auth')
class AuthController {
  final TokenGenerator _tokens;
  final RefreshTokenGenerator _refreshTokens;

  AuthController(this._tokens, this._refreshTokens);

  @Post('/login')
  Future<Response> login(Request request) async {
    final body = await request.json();
    final username = body['username'] as String?;
    final password = body['password'] as String?;

    if (username == null || password == null) {
      throw BadRequestException('Username and password are required');
    }

    if (username == 'admin' && password == 'admin123') {
      return Response.json({
        'access_token': _tokens.generate(username, roles: ['ROLE_ADMIN']),
        'refresh_token': _refreshTokens.generate(username),
      });
    }

    if (username == 'user' && password == 'user123') {
      return Response.json({
        'access_token': _tokens.generate(username, roles: ['ROLE_USER']),
        'refresh_token': _refreshTokens.generate(username),
      });
    }

    throw UnauthorizedException('Invalid credentials');
  }
}
