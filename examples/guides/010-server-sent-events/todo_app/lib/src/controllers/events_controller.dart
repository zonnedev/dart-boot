import 'dart:async';
import 'package:boot/boot.dart';
import '../services/notification_stream.dart';

part 'events_controller.g.dart';

@Controller('/events')
class EventsController {
  final NotificationStream _notifications;
  EventsController(this._notifications);

  @Get('/time')
  Stream<SseEvent> time(Request request) async* {
    while (true) {
      yield SseEvent(data: DateTime.now().toIso8601String());
      await Future.delayed(Duration(seconds: 1));
    }
  }

  @Get('/notifications')
  Stream<SseEvent> notifications(Request request) async* {
    var id = 0;
    await for (final message in _notifications.stream) {
      id++;
      yield SseEvent(
        data: message,
        event: 'notification',
        id: '$id',
      );
    }
  }
}
