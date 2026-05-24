# Guide 003: Add Authentication

## What you'll build

Add JWT-based authentication to the Todo app. Some endpoints will be public, others will require a valid token.

## What you'll learn

- How `boot_security_jwt` auto-wires authentication
- How to write a login endpoint using `TokenGenerator`
- How to protect endpoints with `@Secured` and intercept-url-map
- How to access the authenticated user in controllers
- How to test protected endpoints

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: Add boot_security_jwt

**`pubspec.yaml`** — add under dependencies:

```yaml
dependencies:
  boot: ^0.1.0
  boot_security_jwt: ^0.1.0
```

```bash
dart pub get
```

That's all you need. `boot_security_jwt` is a Boot library — it auto-registers:
- `JwtTokenGenerator` → creates access tokens
- `JwtRefreshTokenGenerator` → creates refresh tokens
- `JwtTokenValidator` → verifies tokens
- `BearerTokenReader` → extracts tokens from `Authorization: Bearer <token>`
- `JwtAuthenticationProvider` → ties it all together

---

## Step 2: Configure security

**`application.yml`**

```yaml
boot:
  env: dev
  security:
    enabled: true
    jwt:
      secret: boot-guide-secret-change-in-production
      expiration: 1h
      refresh-expiration: 7d
      issuer: todo-app
    intercept-url-map:
      - pattern: /auth/**
        access: [isAnonymous()]
      - pattern: /todos/**
        access: [isAuthenticated()]
```

This means:
- `/auth/**` — anyone can access (login endpoint)
- `/todos/**` — requires a valid JWT token

---

## Step 3: Create a login controller

**`lib/src/controllers/auth_controller.dart`**

```dart
import 'package:boot/boot.dart';
import 'package:boot_security_jwt/boot_security_jwt.dart';

part 'auth_controller.g.dart';

@Controller('/auth')
class AuthController {
  final TokenGenerator _tokens;
  final RefreshTokenGenerator _refreshTokens;

  AuthController(this._tokens, this._refreshTokens);

  @Post('/login')
  Future<Response> login(Request request) async {
    final body = await request.json();
    final username = body['username'] as String?;
    final password = body['password'] as String?;

    if (username == null || password == null) {
      throw BadRequestException('Username and password are required');
    }

    // Simple hardcoded check for this guide.
    // In a real app, verify against a database with hashed passwords.
    if (username == 'admin' && password == 'admin123') {
      return Response.json({
        'access_token': _tokens.generate(username, roles: ['ROLE_ADMIN']),
        'refresh_token': _refreshTokens.generate(username),
      });
    }

    if (username == 'user' && password == 'user123') {
      return Response.json({
        'access_token': _tokens.generate(username, roles: ['ROLE_USER']),
        'refresh_token': _refreshTokens.generate(username),
      });
    }

    throw UnauthorizedException('Invalid credentials');
  }
}
```

**What's happening:**
- `TokenGenerator` and `RefreshTokenGenerator` are injected automatically — provided by `boot_security_jwt`
- You just call `.generate()` with the subject and roles
- No need to write JWT signing logic — the framework handles it

---

## Step 4: Protect the todo endpoints

**`lib/src/controllers/todo_controller.dart`** — add `@Secured`:

```dart
import 'package:boot/boot.dart';

part 'todo_controller.g.dart';

@Controller('/todos')
@Secured([SecurityRule.isAuthenticated])
class TodoController {
  // ... same as before
}
```

---

## Step 5: Access the authenticated user

Add a method that uses the current user:

```dart
@Get('/mine')
Future<Response> mine(Request request, Authentication auth) async {
  return Response.json({'user': auth.name, 'roles': auth.roles});
}
```

**Important:** Put specific routes (`/mine`) before parameterized routes (`/<id>`) in your controller.

For optional auth (works for both authenticated and anonymous):

```dart
@Get('/greeting')
Future<Response> greeting(Request request, Authentication? auth) async {
  final name = auth?.name ?? 'Guest';
  return Response.json({'message': 'Hello, $name!'});
}
```

---

## Step 6: Update exports

**`lib/todo_app.dart`**

```dart
library todo_app;

export 'src/controllers/auth_controller.dart';
export 'src/controllers/todo_controller.dart';
export 'src/models/todo.dart';
```

---

## Step 7: Build and test manually

```bash
boot build
boot serve
```

**Login:**

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

Response:
```json
{"access_token": "eyJ...", "refresh_token": "eyJ..."}
```

**Access protected endpoint:**

```bash
curl http://localhost:8080/todos/ \
  -H "Authorization: Bearer eyJ..."
```

**Without token:**

```bash
curl http://localhost:8080/todos/
# → 401 {"error": "Unauthorized"}
```

---

## Step 8: Write automated tests

**`test/auth_test.dart`**

```dart
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
  });
}
```

Run:

```bash
boot test
```

---

## Step 9: Add role-based access (optional)

Restrict specific endpoints to certain roles:

```dart
@Delete('/<id>')
@Secured(['ROLE_ADMIN'])
Future<Response> delete(Request request, @PathParam() String id) async {
  // only admins can delete
}
```

**Test:**

```dart
test('non-admin cannot delete', () async {
  await bootTest($configure, test: (client, container) async {
    final tokens = container.get<TokenGenerator>();
    final userToken = tokens.generate('user', roles: ['ROLE_USER']);

    final res = await client.delete('/todos/1', headers: {
      'Authorization': 'Bearer $userToken',
    });
    res.expectStatus(403);
  });
});
```

---

## Step 10: Override token extraction (optional)

If you need tokens from cookies instead of the Authorization header:

```dart
import 'package:boot/boot.dart';
import 'package:boot_security_jwt/boot_security_jwt.dart';

part 'cookie_token_reader.g.dart';

@Singleton()
@Replaces(TokenReader)
class CookieTokenReader implements TokenReader {
  @override
  String? read(AuthenticationRequest request) {
    final cookie = request.headers['cookie'];
    if (cookie == null) return null;
    for (final part in cookie.split(';')) {
      final kv = part.trim().split('=');
      if (kv.length == 2 && kv[0] == 'access_token') return kv[1];
    }
    return null;
  }
}
```

The framework uses your `CookieTokenReader` instead of the default `BearerTokenReader`. Everything else (validation, authentication) stays the same.

---

## What you've learned

- `boot_security_jwt` auto-registers all JWT beans — no manual wiring
- `TokenGenerator` / `RefreshTokenGenerator` — inject and call `.generate()`
- `@Secured([SecurityRule.isAuthenticated])` — requires any valid token
- `@Secured(['ROLE_ADMIN'])` — requires a specific role
- `Authentication auth` in controller methods — access the current user
- `intercept-url-map` in YAML — declarative URL-based rules
- `@Replaces(TokenReader)` — swap how tokens are extracted
- In tests, get `TokenGenerator` from container to create tokens directly

## Next steps

- [Guide 004: Add Error Handling](004-add-error-handling.md) — custom exception handlers and error responses
