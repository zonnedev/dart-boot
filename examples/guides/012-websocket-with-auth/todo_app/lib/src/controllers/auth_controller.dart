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

    if (username == 'admin' && password == 'admin123') {
      return Response.json({'token': _jwt.createToken(username!, ['ROLE_ADMIN'])});
    }
    throw UnauthorizedException('Invalid credentials');
  }
}
