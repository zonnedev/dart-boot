import 'package:boot_test/boot_test.dart';
import 'package:boot_security_jwt/boot_security_jwt.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Authentication', () {
    test('login with valid credentials returns tokens', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/auth/login', body: {
          'username': 'admin',
          'password': 'admin123',
        });
        res.expectStatus(200);
        expect(res.json()['access_token'], isNotNull);
        expect(res.json()['refresh_token'], isNotNull);
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
        final tokens = container.get<TokenGenerator>();
        final token = tokens.generate('testuser', roles: ['ROLE_USER']);

        final res = await client.get('/todos/', headers: {
          'Authorization': 'Bearer $token',
        });
        res.expectStatus(200);
      });
    });

    test('invalid token returns 401', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/', headers: {
          'Authorization': 'Bearer invalid-garbage-token',
        });
        res.expectStatus(401);
      });
    });

    test('admin can delete', () async {
      await bootTest($configure, test: (client, container) async {
        final tokens = container.get<TokenGenerator>();
        final token = tokens.generate('admin', roles: ['ROLE_ADMIN']);
        final headers = {'Authorization': 'Bearer $token'};

        // Create a todo
        await client.post('/todos/', body: {'title': 'Test'}, headers: headers);

        // Delete it
        final res = await client.delete('/todos/1', headers: headers);
        res.expectStatus(204);
      });
    });

    test('non-admin cannot delete', () async {
      await bootTest($configure, test: (client, container) async {
        final tokens = container.get<TokenGenerator>();
        final adminToken = tokens.generate('admin', roles: ['ROLE_ADMIN']);
        final userToken = tokens.generate('user', roles: ['ROLE_USER']);

        // Create a todo as admin
        await client.post('/todos/', body: {'title': 'Test'}, headers: {
          'Authorization': 'Bearer $adminToken',
        });

        // Try to delete as non-admin
        final res = await client.delete('/todos/1', headers: {
          'Authorization': 'Bearer $userToken',
        });
        res.expectStatus(403);
      });
    });
  });
}
