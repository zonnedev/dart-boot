import 'package:boot/boot.dart';
import '../services/notification_dispatcher.dart';

part 'notification_controller.g.dart';

@Controller('/notifications')
class NotificationController {
  final NotificationDispatcher _dispatcher;

  NotificationController(this._dispatcher);

  @Post('/broadcast')
  Future<Response> broadcast(Request request) async {
    final body = await request.json();
    await _dispatcher.broadcast(body['to'] as String, body['message'] as String);
    return Response.json({'sent_via': 'all'});
  }
}
