# boot_security_jwt

JWT authentication module for the Boot Framework. Add it to your app and get token-based auth with zero boilerplate.

## Quick Start

```yaml
dependencies:
  boot: ^0.1.0
  boot_security_jwt: ^0.1.0
```

```yaml
# application.yml
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

## What's Auto-Registered

| Bean | Interface | Purpose |
|---|---|---|
| `JwtTokenGenerator` | `TokenGenerator` | Creates access tokens |
| `JwtRefreshTokenGenerator` | `RefreshTokenGenerator` | Creates refresh tokens |
| `JwtTokenValidator` | `TokenValidator` | Verifies token signature + expiry |
| `DefaultTokenReader` | `TokenReader` | Reads `Authorization: Bearer` header |
| `JwtAuthenticationProvider` | `AuthenticationProvider` | Ties reader + validator together |

## Usage in Controllers

```dart
@Controller('/auth')
class AuthController {
  final TokenGenerator _tokens;
  final RefreshTokenGenerator _refreshTokens;

  AuthController(this._tokens, this._refreshTokens);

  @Post('/login')
  Future<Response> login(Request request) async {
    final body = await request.json();
    // validate credentials...
    return Response.json({
      'access_token': _tokens.generate(userId, roles: ['ROLE_USER']),
      'refresh_token': _refreshTokens.generate(userId),
    });
  }
}
```

## Override Any Component

```dart
// Read tokens from cookies instead of Authorization header
@Singleton()
@Replaces(TokenReader)
class CookieTokenReader implements TokenReader {
  @override
  String? read(AuthenticationRequest request) =>
      request.headers['cookie']?.extractCookie('token');
}
```

## Configuration Reference

| Key | Default | Description |
|---|---|---|
| `boot.security.jwt.secret` | (required) | HMAC signing key |
| `boot.security.jwt.expiration` | `1h` | Access token lifetime |
| `boot.security.jwt.refresh-expiration` | `7d` | Refresh token lifetime |
| `boot.security.jwt.issuer` | (none) | `iss` claim value |

Duration formats: `500ms`, `30s`, `15m`, `2h`, `7d`
