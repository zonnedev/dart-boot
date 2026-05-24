import 'package:boot/boot.dart';

part 'health_controller.g.dart';

@Controller('/health')
class HealthController {
  @Get('/')
  Future<Response> health(Request request) async {
    return Response.json({'status': 'UP'});
  }
}
