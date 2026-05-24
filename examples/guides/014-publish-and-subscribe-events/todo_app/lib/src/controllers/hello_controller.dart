import 'package:boot/boot.dart';

part 'hello_controller.g.dart';

@Controller('/hello')
class HelloController {
  @Get('/')
  Future<Response> hello(Request request) async {
    return Response.json({'message': 'Hello from Boot!'});
  }

  @Get('/<name>')
  Future<Response> greet(Request request, @PathParam() String name) async {
    return Response.json({'message': 'Hello, $name!'});
  }
}
