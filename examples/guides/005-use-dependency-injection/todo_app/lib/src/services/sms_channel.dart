import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'sms_channel.g.dart';

@Singleton()
@Named('sms')
class SmsChannel implements NotificationChannel {
  @override
  String get name => 'sms';

  @override
  Future<void> send(String recipient, String message) async {
    print('📱 Sending SMS to $recipient: $message');
  }
}
