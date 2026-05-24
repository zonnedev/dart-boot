import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'email_channel.g.dart';

@Singleton()
@Primary()
class EmailChannel implements NotificationChannel {
  @override
  String get name => 'email';

  @override
  Future<void> send(String recipient, String message) async {
    print('📧 Sending email to $recipient: $message');
  }
}
