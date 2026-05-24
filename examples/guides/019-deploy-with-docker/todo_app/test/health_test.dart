import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Deploy with Docker', () {
    test('health endpoint returns UP', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/health/');
        res.expectStatus(200);
        expect(res.json()['status'], 'UP');
      });
    });
  });
}
