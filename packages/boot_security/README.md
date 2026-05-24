# boot_security

Security module for the Boot Framework — authentication, authorization, and token interfaces.

## Features

- `AuthenticationProvider` — implement to add any auth method
- `SecurityFilter` — enforces intercept-url-map and `@Secured` annotations
- `@Secured` — method/class-level access control via route metadata
- `TokenReader`, `TokenValidator`, `TokenGenerator`, `RefreshTokenGenerator` — pluggable token interfaces
- `BearerTokenReader` — default token extraction from `Authorization: Bearer` header
- `Authentication` — represents an authenticated user (name, roles, attributes)

## Usage

This package is included automatically via `boot_http`. You don't need to depend on it directly unless you're writing a security module (like `boot_security_jwt`).

```yaml
# For security module authors:
dependencies:
  boot_security: ^0.1.0
```

## Interfaces

```dart
abstract class TokenReader {
  String? read(AuthenticationRequest request);
}

abstract class TokenValidator {
  Map<String, dynamic>? validate(String token);
}

abstract class TokenGenerator {
  String generate(String subject, {List<String> roles, Map<String, dynamic> claims});
}

abstract class RefreshTokenGenerator {
  String generate(String subject);
}
```

## Override Example

```dart
@Singleton()
@Replaces(TokenReader)
class CookieTokenReader implements TokenReader {
  @override
  String? read(AuthenticationRequest request) {
    // read from cookie instead of Authorization header
  }
}
```
