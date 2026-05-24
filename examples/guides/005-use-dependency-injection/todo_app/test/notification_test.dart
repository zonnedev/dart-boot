import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/notification_channel.dart';
import 'package:todo_app/src/services/email_channel.dart';
import 'package:todo_app/src/services/sms_channel.dart';
import 'package:test/test.dart';

void main() {
  group('Dependency Injection', () {
    test('default NotificationChannel is EmailChannel (@Primary)', () async {
      await bootTest($configure, test: (client, container) async {
        final channel = container.get<NotificationChannel>();
        expect(channel, isA<EmailChannel>());
        expect(channel.name, 'email');
      });
    });

    test('@Named selects specific implementation', () async {
      await bootTest($configure, test: (client, container) async {
        final sms = container.container.getNamed<NotificationChannel>('sms');
        expect(sms, isA<SmsChannel>());
        expect(sms.name, 'sms');
      });
    });

    test('getAll returns all implementations', () async {
      await bootTest($configure, test: (client, container) async {
        final all = container.container.getAll<NotificationChannel>();
        expect(all.length, 3);
        expect(all.map((c) => c.name).toSet(), {'email', 'sms', 'push'});
      });
    });

    test('broadcast endpoint sends to all channels', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/notifications/broadcast', body: {
          'to': 'test@test.com',
          'message': 'Test',
        });
        res.expectStatus(200);
        expect(res.json()['sent_via'], 'all');
      });
    });
  });
}
