import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Todo API integration', () {
    test('full CRUD lifecycle', () async {
      await bootTest($configure, test: (client, container) async {
        final createRes = await client.post('/todos/', body: {'title': 'Integration test'});
        createRes.expectStatus(201);
        final id = createRes.json()['id'];

        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(200);
        expect(getRes.json()['title'], 'Integration test');

        final listRes = await client.get('/todos/');
        listRes.expectStatus(200);
        expect(listRes.jsonList(), isNotEmpty);

        final deleteRes = await client.delete('/todos/$id');
        deleteRes.expectStatus(204);

        final afterRes = await client.get('/todos/$id');
        afterRes.expectStatus(404);
      });
    });

    test('validation errors', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
        expect(res.json()['error'], contains('required'));
      });
    });
  });
}
