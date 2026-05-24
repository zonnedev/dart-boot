import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/notification_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Server-Sent Events', () {
    test('NotificationStream delivers messages', () async {
      await bootTest($configure, test: (client, container) async {
        final stream = container.get<NotificationStream>();
        final received = <String>[];

        final sub = stream.stream.listen((msg) => received.add(msg));

        stream.notify('Hello');
        stream.notify('World');

        await Future.delayed(Duration(milliseconds: 10));

        expect(received, ['Hello', 'World']);
        await sub.cancel();
      });
    });

    test('creating a todo pushes notification', () async {
      await bootTest($configure, test: (client, container) async {
        final stream = container.get<NotificationStream>();
        final received = <String>[];
        final sub = stream.stream.listen((msg) => received.add(msg));

        await client.post('/todos/', body: {'title': 'Test SSE'});

        await Future.delayed(Duration(milliseconds: 10));
        expect(received.length, 1);
        expect(received.first, contains('Test SSE'));
        await sub.cancel();
      });
    });
  });
}
