import 'package:boot/boot.dart';
import 'email_service.dart';

part 'fake_email_service.g.dart';

@Singleton()
@Requires(notEnv: ['prod'])
class FakeEmailService implements EmailService {
  @override
  Future<void> send(String to, String body) async {
    print('📧 [FAKE] Would send to $to: $body');
  }
}
