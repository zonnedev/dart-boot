import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/email_service.dart';
import 'package:todo_app/src/services/fake_email_service.dart';
import 'package:todo_app/src/services/smtp_email_service.dart';
import 'package:test/test.dart';

void main() {
  group('Environment configuration', () {
    test('test env loads FakeEmailService', () async {
      await bootTest($configure, test: (client, container) async {
        final email = container.get<EmailService>();
        expect(email, isA<FakeEmailService>());
      });
    });

    test('prod env loads SmtpEmailService', () async {
      await bootTest($configure, env: 'prod', test: (client, container) async {
        final email = container.get<EmailService>();
        expect(email, isA<SmtpEmailService>());
      });
    });

    test('FakeEmailService not loaded in prod', () async {
      await bootTest($configure, env: 'prod', test: (client, container) async {
        expect(container.has<FakeEmailService>(), isFalse);
      });
    });
  });
}
