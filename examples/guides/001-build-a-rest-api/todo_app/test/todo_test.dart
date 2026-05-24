import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('TodoController', () {
    test('GET /todos/ returns empty list initially', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/');
        res.expectStatus(200);
        expect(res.jsonList(), isEmpty);
      });
    });

    test('POST /todos/ creates a todo', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {
          'title': 'Buy groceries',
        });
        res.expectStatus(201);
        expect(res.json()['title'], 'Buy groceries');
        expect(res.json()['id'], isNotNull);
        expect(res.json()['completed'], false);
      });
    });

    test('POST /todos/ without title returns 400', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
        expect(res.json()['error'], 'Title is required');
      });
    });

    test('GET /todos/<id> returns the todo', () async {
      await bootTest($configure, test: (client, container) async {
        final createRes = await client.post('/todos/', body: {'title': 'Test'});
        final id = createRes.json()['id'];

        final res = await client.get('/todos/$id');
        res.expectStatus(200);
        expect(res.json()['title'], 'Test');
      });
    });

    test('GET /todos/<id> returns 404 for missing todo', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/999');
        res.expectStatus(404);
      });
    });

    test('DELETE /todos/<id> removes the todo', () async {
      await bootTest($configure, test: (client, container) async {
        final createRes = await client.post('/todos/', body: {'title': 'Delete me'});
        final id = createRes.json()['id'];

        final deleteRes = await client.delete('/todos/$id');
        deleteRes.expectStatus(204);

        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(404);
      });
    });
  });
}
