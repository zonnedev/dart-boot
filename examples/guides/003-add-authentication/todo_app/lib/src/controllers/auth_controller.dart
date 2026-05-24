import 'package:boot/boot.dart';
import '../services/jwt_service.dart';

part 'auth_controller.g.dart';

@Controller('/auth')
class AuthController {
  final JwtService _jwt;

  AuthController(this._jwt);

  @Post('/login')
  Future<Response> login(Request request) async {
    final body = await request.json();
    final username = body['username'] as String?;
    final password = body['password'] as String?;

    if (username == null || password == null) {
      throw BadRequestException('Username and password are required');
    }

    if (username == 'admin' && password == 'admin123') {
      final token = _jwt.createToken(username, ['ROLE_ADMIN']);
      return Response.json({'token': token});
    }

    if (username == 'user' && password == 'user123') {
      final token = _jwt.createToken(username, ['ROLE_USER']);
      return Response.json({'token': token});
    }

    throw UnauthorizedException('Invalid credentials');
  }
}
