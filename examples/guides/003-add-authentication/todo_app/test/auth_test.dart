import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/jwt_service.dart';
import 'package:test/test.dart';

void main() {
  group('Authentication', () {
    test('login with valid credentials returns token', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/auth/login', body: {
          'username': 'admin',
          'password': 'admin123',
        });
        res.expectStatus(200);
        expect(res.json()['token'], isNotNull);
        expect(res.json()['token'], isA<String>());
      });
    });

    test('login with invalid credentials returns 401', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/auth/login', body: {
          'username': 'admin',
          'password': 'wrong',
        });
        res.expectStatus(401);
      });
    });

    test('protected endpoint rejects without token', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/');
        res.expectStatus(401);
      });
    });

    test('protected endpoint works with valid token', () async {
      await bootTest($configure, test: (client, container) async {
        final jwt = container.get<JwtService>();
        final token = jwt.createToken('testuser', ['ROLE_USER']);

        final res = await client.get('/todos/', headers: {
          'Authorization': 'Bearer $token',
        });
        res.expectStatus(200);
      });
    });

    test('expired/invalid token returns 401', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/', headers: {
          'Authorization': 'Bearer invalid-garbage-token',
        });
        res.expectStatus(401);
      });
    });
  });
}
