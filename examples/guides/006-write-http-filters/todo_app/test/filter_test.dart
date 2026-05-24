import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Filters', () {
    test('RequestIdFilter adds x-request-id header', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/');
        res.expectStatus(200);
        expect(res.headers['x-request-id'], isNotNull);
        expect(res.headers['x-request-id']!.length, 16);
      });
    });

    test('each request gets a unique ID', () async {
      await bootTest($configure, test: (client, container) async {
        final res1 = await client.get('/todos/');
        final res2 = await client.get('/todos/');
        expect(res1.headers['x-request-id'], isNot(res2.headers['x-request-id']));
      });
    });

    test('rate limiter blocks after limit exceeded', () async {
      await bootTest($configure, properties: {
        'rate-limit.max': '5',
      }, test: (client, container) async {
        for (var i = 0; i < 5; i++) {
          final res = await client.get('/todos/');
          res.expectStatus(200);
        }

        final blocked = await client.get('/todos/');
        blocked.expectStatus(429);
        expect(blocked.json()['error'], contains('Too many requests'));
        expect(blocked.headers['retry-after'], '60');
      });
    });
  });
}
