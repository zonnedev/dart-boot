import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'push_channel.g.dart';

@Singleton()
@Named('push')
class PushChannel implements NotificationChannel {
  @override
  String get name => 'push';

  @override
  Future<void> send(String recipient, String message) async {
    print('🔔 Sending push to $recipient: $message');
  }
}
