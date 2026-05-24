# Guide 003: Add Authentication

## What you'll build

Add JWT-based authentication to the Todo app. Some endpoints will be public, others will require a valid token.

## What you'll learn

- How to implement an `AuthenticationProvider`
- How to protect endpoints with `@Secured`
- How to configure URL-based access rules
- How to access the authenticated user in controllers
- How to test protected endpoints

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)
- Basic understanding of JWT tokens (we'll explain as we go)

---

## Step 1: Add a JWT dependency

We'll use the `dart_jsonwebtoken` package to create and verify tokens.

**`pubspec.yaml`** — add under dependencies:

```yaml
dependencies:
  boot: ^0.1.0
  dart_jsonwebtoken: ^2.12.0
```

```bash
dart pub get
```

---

## Step 2: Create a JWT service

This service creates and verifies tokens. It's a regular Boot bean.

**`lib/src/services/jwt_service.dart`**

```dart
import 'package:boot/boot.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

part 'jwt_service.g.dart';

/// Creates and verifies JWT tokens.
@Singleton()
class JwtService {
  final String _secret;

  JwtService(@Value('\${auth.jwt.secret:boot-secret-change-me}') this._secret);

  /// Create a token for a user.
  String createToken(String username, List<String> roles) {
    final jwt = JWT({
      'sub': username,
      'roles': roles,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    return jwt.sign(SecretKey(_secret), expiresIn: Duration(hours: 24));
  }

  /// Verify a token. Returns the claims if valid, null if invalid/expired.
  Map<String, dynamic>? verify(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      return jwt.payload as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
```

**What's happening:**

- `@Value('\${auth.jwt.secret:boot-secret-change-me}')` — reads the secret from config, with a default for development. In production, you'd set a real secret.
- `createToken()` — creates a signed JWT with the username and roles inside.
- `verify()` — checks if a token is valid and not expired. Returns the data inside, or null if invalid.

---

## Step 3: Create the authentication provider

This is the core piece. Boot calls this for every request that needs authentication.

**`lib/src/security/jwt_auth_provider.dart`**

```dart
import 'package:boot/boot.dart';
import '../services/jwt_service.dart';

part 'jwt_auth_provider.g.dart';

/// Validates JWT tokens from the Authorization header.
/// Boot discovers this automatically and uses it for all protected endpoints.
@Singleton()
class JwtAuthProvider implements AuthenticationProvider {
  final JwtService _jwt;

  JwtAuthProvider(this._jwt);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    // Look for "Authorization: Bearer <token>" header
    final header = request.authorization;
    if (header == null || !header.startsWith('Bearer ')) return null;

    // Extract and verify the token
    final token = header.substring(7); // remove "Bearer " prefix
    final claims = _jwt.verify(token);
    if (claims == null) return null; // invalid or expired

    // Return the authenticated user
    return Authentication(
      name: claims['sub'] as String,
      roles: List<String>.from(claims['roles'] ?? []),
    );
  }
}
```

**What's happening:**

- `implements AuthenticationProvider` — this tells Boot "use me for authentication"
- Boot automatically discovers this bean and calls `authenticate()` on every request that needs auth
- If the method returns `Authentication` → the user is authenticated
- If it returns `null` → this provider can't authenticate the request (maybe another provider can, or it's rejected)
- The `Authentication` object carries the username and roles — available in controllers later

---

## Step 4: Create a login endpoint

Users need a way to get a token. Create a simple login controller:

**`lib/src/controllers/auth_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../services/jwt_service.dart';

part 'auth_controller.g.dart';

/// Handles login — issues JWT tokens.
@Controller('/auth')
class AuthController {
  final JwtService _jwt;

  AuthController(this._jwt);

  /// POST /auth/login — returns a JWT token.
  /// In a real app, you'd verify the password against a database.
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
      final token = _jwt.createToken(username, ['ROLE_ADMIN']);
      return Response.json({'token': token});
    }

    if (username == 'user' && password == 'user123') {
      final token = _jwt.createToken(username, ['ROLE_USER']);
      return Response.json({'token': token});
    }

    throw UnauthorizedException('Invalid credentials');
  }
}
```

---

## Step 5: Protect the todo endpoints

Add `@Secured` to require authentication:

**`lib/src/controllers/todo_controller.dart`** — add the annotation:

```dart
import 'package:boot/boot.dart';
import '../models/todo.dart';

part 'todo_controller.g.dart';

/// All endpoints in this controller require authentication.
@Controller('/todos')
@Secured(['isAuthenticated()'])
class TodoController {
  // ... same as before
}
```

**What's happening:** `@Secured(['isAuthenticated()'])` means every endpoint in this controller requires a valid token. Without it, the request gets a 401 response.

---

## Step 6: Access the authenticated user

You can inject `Authentication` into any controller method. Add this to your `TodoController`:

```dart
@Get('/mine')
Future<Response> mine(Request request, Authentication auth) async {
  return Response.json({'user': auth.name, 'roles': auth.roles});
}
```

**Important:** Put this method **before** `@Get('/<id>')` in your controller. Routes are matched in order — if `/<id>` comes first, it will catch `/mine` and try to use "mine" as an ID.

The correct order in your controller:

```dart
@Controller('/todos')
@Secured(['isAuthenticated()'])
class TodoController {
  // Specific routes first
  @Get('/mine')
  Future<Response> mine(Request request, Authentication auth) async { ... }

  @Get('/')
  Future<Response> list(Request request) async { ... }

  // Parameterized routes last
  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async { ... }
}
```

If you declare `Authentication?` (nullable), the endpoint works for both authenticated and anonymous users:

```dart
@Get('/greeting')
Future<Response> greeting(Request request, Authentication? auth) async {
  final name = auth?.name ?? 'Guest';
  return Response.json({'message': 'Hello, $name!'});
}
```

---

## Step 7: Enable security in configuration

Add to your `application.yml`:

```yaml
boot:
  env: dev
  security:
    enabled: true
    intercept-url-map:
      - pattern: /auth/**
        access: [isAnonymous()]
      - pattern: /todos/public
        access: [isAnonymous()]
      - pattern: /todos/**
        access: [isAuthenticated()]
```

This means:
- `/auth/login` — anyone can access (no token needed)
- `/todos/public` — anyone can access
- `/todos/**` — requires authentication
- `@Secured` annotations on individual methods add further restrictions (like role checks)

---

## Step 8: Update exports

**`lib/todo_app.dart`**

```dart
library todo_app;

export 'src/controllers/auth_controller.dart';
export 'src/controllers/todo_controller.dart';
export 'src/models/todo.dart';
export 'src/security/jwt_auth_provider.dart';
export 'src/services/jwt_service.dart';
```

---

## Step 9: Build and test manually

```bash
boot build
boot serve
```

**Try accessing todos without a token:**

```bash
curl http://localhost:8080/todos/
```

Response:
```json
{"error": "Unauthorized"}
```
Status: 401

**Login to get a token:**

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

Response:
```json
{"token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
```

**Use the token to access todos:**

```bash
curl http://localhost:8080/todos/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

Response:
```json
[]
```
Status: 200 ✓

---

## Step 10: Write automated tests

**`test/auth_test.dart`**

```dart
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
        // Get a token
        final jwt = container.get<JwtService>();
        final token = jwt.createToken('testuser', ['ROLE_USER']);

        // Use it
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
```

Run:

```bash
boot test
```

---

## Step 11: Add role-based access (optional)

Restrict specific endpoints to certain roles:

```dart
@Delete('/<id>')
@Secured(['ROLE_ADMIN'])  // only admins can delete
Future<Response> delete(Request request, @PathParam() String id) async {
  // ...
}
```

**Test:**

```dart
test('non-admin cannot delete', () async {
  await bootTest($configure, test: (client, container) async {
    final jwt = container.get<JwtService>();
    final userToken = jwt.createToken('user', ['ROLE_USER']); // not admin

    final res = await client.delete('/todos/1', headers: {
      'Authorization': 'Bearer $userToken',
    });
    res.expectStatus(403); // Forbidden — authenticated but wrong role
  });
});

test('admin can delete', () async {
  await bootTest($configure, test: (client, container) async {
    final jwt = container.get<JwtService>();
    final adminToken = jwt.createToken('admin', ['ROLE_ADMIN']);

    final res = await client.delete('/todos/1', headers: {
      'Authorization': 'Bearer $adminToken',
    });
    // 204 or 404 depending on whether the todo exists — but NOT 403
    expect(res.statusCode, isNot(403));
  });
});
```

---

## What you've learned

- `AuthenticationProvider` — implement this to add any auth method (JWT, API key, mTLS, etc.)
- Boot auto-discovers providers — just annotate with `@Singleton()` and implement the interface
- `@Secured(['isAuthenticated()'])` — requires any valid authentication
- `@Secured(['ROLE_ADMIN'])` — requires a specific role
- `Authentication auth` in controller methods — access the current user
- `Authentication? auth` — optional, works for both authenticated and anonymous
- `intercept-url-map` in YAML — declarative URL-based rules
- In tests, create tokens directly via `JwtService` — no need to call the login endpoint

## Next steps

- [Guide 004: Add Error Handling](004-add-error-handling.md) — custom exception handlers and error responses
