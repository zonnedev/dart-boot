import 'package:boot/boot.dart';
import 'email_service.dart';

part 'smtp_email_service.g.dart';

@Singleton()
@Requires(env: ['prod'])
class SmtpEmailService implements EmailService {
  @override
  Future<void> send(String to, String body) async {
    print('📧 [SMTP] Sending to $to: $body');
  }
}
