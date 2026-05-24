# Security

Unified authentication and authorization for HTTP and WebSocket.

## Packages

| Package | Purpose |
|---|---|
| `boot_security` | Interfaces, models, SecurityFilter — included via `boot_http` |
| `boot_security_jwt` | JWT implementation — add to your app for token-based auth |

## Quick Start with JWT

**1. Add dependency:**

```yaml
dependencies:
  boot: ^0.1.0
  boot_security_jwt: ^0.1.0
```

**2. Configure in `application.yml`:**

```yaml
boot:
  security:
    enabled: true
    jwt:
      secret: change-me-in-production
      expiration: 1h
      refresh-expiration: 7d
      issuer: my-app
    intercept-url-map:
      - pattern: /auth/**
        access: [isAnonymous()]
      - pattern: /**
        access: [isAuthenticated()]
```

**3. Write a login controller:**

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
    final user = await _db.findByUsername(body['username']);
    if (user == null || !verifyPassword(body['password'], user.hash)) {
      throw UnauthorizedException('Invalid credentials');
    }
    return Response.json({
      'access_token': _tokens.generate(user.id, roles: user.roles),
      'refresh_token': _refreshTokens.generate(user.id),
    });
  }

  @Post('/refresh')
  Future<Response> refresh(Request request) async {
    final body = await request.json();
    final refreshToken = body['refresh_token'] as String?;
    if (refreshToken == null) throw BadRequestException('Missing refresh_token');

    // Validate the refresh token
    final validator = container.get<TokenValidator>();
    final claims = validator.validate(refreshToken);
    if (claims == null || claims['type'] != 'refresh') {
      throw UnauthorizedException('Invalid refresh token');
    }

    final subject = claims['sub'] as String;
    // Look up current roles from DB
    final user = await _db.findById(subject);
    return Response.json({
      'access_token': _tokens.generate(subject, roles: user.roles),
    });
  }
}
```

**That's it.** Everything else is auto-wired:
- `JwtTokenGenerator` registered as `TokenGenerator`
- `JwtRefreshTokenGenerator` registered as `RefreshTokenGenerator`
- `JwtTokenValidator` registered as `TokenValidator`
- `BearerTokenReader` registered as `TokenReader`
- `JwtAuthenticationProvider` registered as `AuthenticationProvider`
- `SecurityFilter` enforces intercept-url-map rules

## Architecture

```
Request → SecurityFilter → TokenReader.read() → TokenValidator.validate() → Authentication
                                ↑                        ↑
                        BearerTokenReader          JwtTokenValidator
                        (reads Bearer header)      (verifies JWT signature)
```

All components are replaceable via `@Replaces`:

```dart
@Singleton()
@Replaces(TokenReader)
class CookieTokenReader implements TokenReader {
  @override
  String? read(AuthenticationRequest request) {
    return request.headers['cookie']
        ?.split(';')
        .map((c) => c.trim().split('='))
        .where((c) => c[0] == 'access_token')
        .map((c) => c[1])
        .firstOrNull;
  }
}
```

## Interfaces

### TokenReader

Extracts a token string from the request. Default: `BearerTokenReader` (reads `Authorization: Bearer <token>`).

```dart
abstract class TokenReader {
  String? read(AuthenticationRequest request);
}
```

### TokenValidator

Validates a token and returns its claims. Default: `JwtTokenValidator`.

```dart
abstract class TokenValidator {
  Map<String, dynamic>? validate(String token);
}
```

### TokenGenerator

Creates access tokens. Default: `JwtTokenGenerator`.

```dart
abstract class TokenGenerator {
  String generate(String subject, {List<String> roles, Map<String, dynamic> claims});
}
```

### RefreshTokenGenerator

Creates refresh tokens. Default: `JwtRefreshTokenGenerator`.

```dart
abstract class RefreshTokenGenerator {
  String generate(String subject);
}
```

### AuthenticationProvider

The top-level interface. `JwtAuthenticationProvider` composes `TokenReader` + `TokenValidator`. You can also implement this directly for non-token auth (API keys, mTLS).

```dart
abstract class AuthenticationProvider {
  Future<Authentication?> authenticate(AuthenticationRequest request);
}
```

## Custom Authentication Providers

For auth methods that don't use tokens (API keys, mTLS), implement `AuthenticationProvider` directly:

### API Key Auth

```dart
@Singleton()
@Order(2)
class ApiKeyAuthProvider implements AuthenticationProvider {
  final ApiKeyRepository _keys;
  ApiKeyAuthProvider(this._keys);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final key = request.headers['x-api-key'];
    if (key == null) return null;

    final owner = await _keys.findByKey(key);
    if (owner == null) return null;

    return Authentication(name: owner.name, roles: owner.roles);
  }
}
```

### mTLS Certificate Auth

```dart
@Singleton()
@Order(0)  // highest priority — check certs first
class MtlsAuthProvider implements AuthenticationProvider {
  final DeviceRegistry _devices;
  MtlsAuthProvider(this._devices);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final certs = request.clientCertificates;
    if (certs == null || certs.isEmpty) return null;

    final cert = certs.first as X509Certificate;
    final cn = _extractCN(cert.subject);

    final device = await _devices.findByCN(cn);
    if (device == null) return null;

    return Authentication(name: cn, roles: ['device'], attributes: {'deviceId': device.id});
  }
}
```

## Multiple Auth Methods

Boot tries all `AuthenticationProvider` beans in `@Order` sequence. First non-null result wins:

```dart
@Singleton() @Order(0) class MtlsAuthProvider implements AuthenticationProvider { ... }
@Singleton() @Order(1) class JwtAuthenticationProvider implements AuthenticationProvider { ... }  // from boot_security_jwt
@Singleton() @Order(2) class ApiKeyAuthProvider implements AuthenticationProvider { ... }
```

- IoT devices authenticate via mTLS cert
- Web users authenticate via JWT
- External services authenticate via API key

## Intercept URL Map

Declarative URL-based access rules:

```yaml
boot:
  security:
    enabled: true
    default-access: isAuthenticated()
    intercept-url-map:
      - pattern: /public/**
        access: [isAnonymous()]
      - pattern: /api/**
        access: [isAuthenticated()]
      - pattern: /admin/**
        access: [ROLE_ADMIN]
      - pattern: /health
        access: [isAnonymous()]
```

## @Secured Annotation

Method-level access control:

```dart
@Controller('/admin')
@Secured([SecurityRule.isAuthenticated])
class AdminController {
  @Get('/dashboard')
  @Secured(['ROLE_ADMIN'])
  Future<Response> dashboard(Request req) async { ... }

  @Get('/reports')
  @Secured(['ROLE_ADMIN', 'ROLE_ANALYST'])  // either role works
  Future<Response> reports(Request req) async { ... }
}
```

## Accessing Authentication in Controllers

```dart
// Required — 401 if not authenticated
@Get('/me')
Future<Response> me(Request req, Authentication auth) async {
  return Response.json({'name': auth.name, 'roles': auth.roles});
}

// Optional — null if not authenticated
@Get('/greeting')
Future<Response> greeting(Request req, Authentication? auth) async {
  final name = auth?.name ?? 'Guest';
  return Response.json({'message': 'Hello, $name'});
}
```

## AuthenticationRequest

Every provider receives the full connection context:

```dart
class AuthenticationRequest {
  String? authorization;             // Authorization header value
  Map<String, String> headers;       // All request headers
  Map<String, String> queryParams;   // Query parameters
  String path;                       // Request path
  String method;                     // HTTP method
  List<dynamic>? clientCertificates; // mTLS client certs
  bool isTls;                        // Is this a TLS connection?
  String? remoteAddress;             // Client IP
}
```

## TLS/mTLS Configuration

```yaml
boot:
  server:
    ssl:
      enabled: true
      cert: certs/server.pem
      key: certs/server-key.pem
      client-auth: required       # none | optional | required
      trust-store: certs/ca.pem   # CA that signed client certs
```

## WebSocket Authentication

Same providers, same flow — see [WebSockets](websockets.md#authentication-on-upgrade).

```yaml
boot:
  websocket:
    auth: true  # uses same AuthenticationProvider beans
```

## Testing

```dart
test('protected endpoint rejects without token', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/api/users');
    res.expectStatus(401);
  });
});

test('protected endpoint works with valid token', () async {
  await bootTest($configure, test: (client, container) async {
    final tokens = container.get<TokenGenerator>();
    final token = tokens.generate('alice', roles: ['ROLE_USER']);

    final res = await client.get('/api/users', headers: {
      'Authorization': 'Bearer $token',
    });
    res.expectStatus(200);
  });
});

test('admin endpoint rejects wrong role', () async {
  await bootTest($configure, test: (client, container) async {
    final tokens = container.get<TokenGenerator>();
    final token = tokens.generate('alice', roles: ['ROLE_USER']);

    final res = await client.get('/admin/dashboard', headers: {
      'Authorization': 'Bearer $token',
    });
    res.expectStatus(403);
  });
});
```

## JWT Configuration Reference

| YAML Key | Default | Description |
|---|---|---|
| `boot.security.jwt.secret` | (required) | HMAC signing key |
| `boot.security.jwt.expiration` | `1h` | Access token lifetime |
| `boot.security.jwt.refresh-expiration` | `7d` | Refresh token lifetime |
| `boot.security.jwt.issuer` | (none) | `iss` claim — rejects tokens with wrong issuer |

Duration formats: `500ms`, `30s`, `15m`, `2h`, `7d`
