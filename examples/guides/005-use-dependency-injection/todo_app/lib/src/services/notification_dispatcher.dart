import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'notification_dispatcher.g.dart';

@Singleton()
class NotificationDispatcher {
  final BeanContainer _container;

  NotificationDispatcher(this._container);

  Future<void> broadcast(String recipient, String message) async {
    final channels = _container.getAll<NotificationChannel>();
    for (final channel in channels) {
      await channel.send(recipient, message);
    }
  }
}
