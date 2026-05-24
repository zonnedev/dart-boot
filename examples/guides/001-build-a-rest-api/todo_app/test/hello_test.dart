import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('GET /hello returns greeting', () async {
    await bootTest($configure, test: (client, container) async {
      final res = await client.get('/hello/');
      res.expectStatus(200);
      expect(res.json()['message'], 'Hello from Boot!');
    });
  });
}
