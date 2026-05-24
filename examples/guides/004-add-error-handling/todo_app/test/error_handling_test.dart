import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Error handling', () {
    test('todo limit returns 429 with details', () async {
      await bootTest($configure, test: (client, container) async {
        for (var i = 0; i < 10; i++) {
          final res = await client.post('/todos/', body: {'title': 'Todo $i'});
          res.expectStatus(201);
        }

        final res = await client.post('/todos/', body: {'title': 'Too many'});
        res.expectStatus(429);
        expect(res.json()['error'], 'Todo limit reached');
        expect(res.json()['current'], 10);
        expect(res.json()['max'], 10);
      });
    });

    test('missing title returns 400', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
        expect(res.json()['error'], 'Title is required');
      });
    });

    test('not found returns 404', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/999');
        res.expectStatus(404);
        expect(res.json()['error'], contains('not found'));
      });
    });
  });
}
