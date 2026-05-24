# Security

Unified authentication and authorization for HTTP and WebSocket.

## Authentication Providers

Implement `AuthenticationProvider` to add an auth method. Boot tries all providers in order — first non-null result wins.

### JWT Token Auth

```dart
import 'package:boot/boot.dart';
part 'jwt_auth_provider.g.dart';

@Singleton()
@Order(1)
class JwtAuthProvider implements AuthenticationProvider {
  final JwtService _jwt;
  JwtAuthProvider(this._jwt);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final header = request.authorization;
    if (header == null || !header.startsWith('Bearer ')) return null;

    final token = header.substring(7);
    final claims = _jwt.verify(token);
    if (claims == null) return null;

    return Authentication(
      name: claims['sub'],
      roles: List<String>.from(claims['roles'] ?? []),
      attributes: {'userId': claims['uid']},
    );
  }
}
```

**Test:**
```dart
test('JWT auth rejects invalid token', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/admin/', headers: {
      'Authorization': 'Bearer invalid-token',
    });
    res.expectStatus(401);
  });
});

test('JWT auth accepts valid token', () async {
  await bootTest($configure, test: (client, container) async {
    final jwt = container.get<JwtService>();
    final token = jwt.sign({'sub': 'alice', 'roles': ['admin']});

    final res = await client.get('/admin/', headers: {
      'Authorization': 'Bearer $token',
    });
    res.expectStatus(200);
  });
});
```

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

**Test:**
```dart
test('API key auth works', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/api/data', headers: {
      'x-api-key': 'valid-key-123',
    });
    res.expectStatus(200);
  });
});
```

### mTLS Certificate Auth

For IoT devices, OCPP chargers, service-to-service:

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

  String _extractCN(String subject) {
    final match = RegExp(r'CN=([^,]+)').firstMatch(subject);
    return match?.group(1) ?? subject;
  }
}
```

**Test:**
```dart
test('mTLS provider registered', () async {
  await bootTest($configure, test: (client, container) async {
    final providers = container.getAll<AuthenticationProvider>();
    expect(providers.any((p) => p is MtlsAuthProvider), isTrue);
  });
});
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

| `client-auth` | Behavior |
|---|---|
| `none` | No client cert requested |
| `optional` | Client cert requested but not required |
| `required` | Connection rejected if no valid client cert |

## AuthenticationRequest

Every provider receives the full connection context:

```dart
class AuthenticationRequest {
  String? authorization;           // Authorization header value
  Map<String, String> headers;     // All request headers
  Map<String, String> queryParams; // Query parameters
  String path;                     // Request path
  String method;                   // HTTP method
  List<dynamic>? clientCertificates; // mTLS client certs
  bool isTls;                      // Is this a TLS connection?
  String? remoteAddress;           // Client IP
}
```

This works identically for HTTP requests and WebSocket upgrades.

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

**Test:**
```dart
test('public endpoints accessible without auth', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/public/info');
    res.expectStatus(200);
  });
});

test('api endpoints require auth', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/api/users');
    res.expectStatus(401);
  });
});

test('admin requires ROLE_ADMIN', () async {
  await bootTest($configure, overrides: (c) {
    c.override<AuthenticationProvider>(FixedRoleAuth(['user']));
  }, test: (client, container) async {
    final res = await client.get('/admin/dashboard', headers: {
      'Authorization': 'Bearer token',
    });
    res.expectStatus(403); // authenticated but wrong role
  });
});
```

## @Secured Annotation

Method-level access control:

```dart
@Controller('/admin')
class AdminController {
  @Get('/dashboard')
  @Secured(['ROLE_ADMIN'])
  Future<Response> dashboard(Request req) async {
    return Response.json({'status': 'admin panel'});
  }

  @Get('/reports')
  @Secured(['ROLE_ADMIN', 'ROLE_ANALYST'])  // either role works
  Future<Response> reports(Request req) async {
    return Response.json({'reports': []});
  }
}
```

**Test:**
```dart
test('Secured endpoint rejects wrong role', () async {
  await bootTest($configure, overrides: (c) {
    c.override<AuthenticationProvider>(FixedRoleAuth(['user']));
  }, test: (client, container) async {
    final res = await client.get('/admin/dashboard', headers: {
      'Authorization': 'Bearer token',
    });
    res.expectStatus(403);
  });
});

test('Secured endpoint allows correct role', () async {
  await bootTest($configure, overrides: (c) {
    c.override<AuthenticationProvider>(FixedRoleAuth(['ROLE_ADMIN']));
  }, test: (client, container) async {
    final res = await client.get('/admin/dashboard', headers: {
      'Authorization': 'Bearer token',
    });
    res.expectStatus(200);
  });
});
```

## Accessing Authentication in Controllers

```dart
@Get('/me')
Future<Response> me(Request req, Authentication auth) async {
  return Response.json({
    'name': auth.name,
    'roles': auth.roles,
  });
}

// Optional — null if not authenticated
@Get('/greeting')
Future<Response> greeting(Request req, Authentication? auth) async {
  final name = auth?.name ?? 'Guest';
  return Response.json({'message': 'Hello, $name'});
}
```

**Test:**
```dart
test('Authentication injected into controller', () async {
  await bootTest($configure, overrides: (c) {
    c.override<AuthenticationProvider>(FixedAuth('alice', ['user']));
  }, test: (client, container) async {
    final res = await client.get('/me', headers: {'Authorization': 'Bearer x'});
    res.expectStatus(200);
    expect(res.json()['name'], 'alice');
  });
});
```

## WebSocket Authentication

Same providers, same flow — see [WebSockets](websockets.md#authentication-on-upgrade).

```yaml
boot:
  websocket:
    auth: true  # uses same AuthenticationProvider beans
```

## Multiple Auth Methods Coexisting

```dart
@Singleton() @Order(0) class MtlsAuthProvider implements AuthenticationProvider { ... }
@Singleton() @Order(1) class JwtAuthProvider implements AuthenticationProvider { ... }
@Singleton() @Order(2) class ApiKeyAuthProvider implements AuthenticationProvider { ... }
```

Boot tries them in `@Order` sequence. First non-null `Authentication` wins. This means:
- IoT devices authenticate via mTLS cert
- Web users authenticate via JWT
- External services authenticate via API key
- All through the same pipeline, no special cases

## Test Helpers

```dart
// Reusable mock auth provider for tests
class FixedAuth implements AuthenticationProvider {
  final String name;
  final List<String> roles;
  FixedAuth(this.name, this.roles);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest req) async {
    if (req.authorization == null && req.clientCertificates == null) return null;
    return Authentication(name: name, roles: roles);
  }
}

class FixedRoleAuth implements AuthenticationProvider {
  final List<String> roles;
  FixedRoleAuth(this.roles);

  @override
  Future<Authentication?> authenticate(AuthenticationRequest req) async {
    if (req.authorization == null) return null;
    return Authentication(name: 'test-user', roles: roles);
  }
}
```
