# Configuration

Boot loads configuration from YAML files with environment overrides and env var support.

## Loading Order (highest priority wins)

1. CLI arguments (`--boot.env=prod`)
2. Programmatic properties (passed to `Boot.run`)
3. Environment variables (`BOOT_ENV`, `PG_HOST`, etc.)
4. `application-{env}.yml` (environment-specific)
5. `application.yml` (base)

## File Structure

```
application.yml          # Base config (always loaded)
application-dev.yml      # Loaded when boot.env=dev
application-prod.yml     # Loaded when boot.env=prod
application-test.yml     # Loaded when boot.env=test
```

## Namespace Convention

All framework config lives under `boot.*`. User config uses any other prefix:

```yaml
# Framework config
boot:
  env: dev
  logging:
    level: info

# User config
pg:
  host: localhost
  port: 5432

myapp:
  feature-flag: true
```

## Injecting Config Values

```dart
@Singleton()
class PgClient {
  PgClient(
    @Value('\${pg.host}') String host,
    @Value('\${pg.port:5432}') int port,     // default: 5432
    @Value('\${pg.database:mydb}') String db,
  );
}
```

Syntax: `${key}` or `${key:default}`.

## Environment Variables

Properties map to env vars automatically:
- `pg.host` → `PG_HOST`
- `boot.logging.level` → `BOOT_LOGGING_LEVEL`
- `my-app.api-key` → `MY_APP_API_KEY`

Rule: replace `.` with `_`, replace `-` with `_`, uppercase.

## Lists

YAML lists are supported:

```yaml
boot:
  logging:
    stacktrace:
      filter:
        exclude:
          - dart:
          - package:shelf/
```

Access in code:

```dart
final excludes = config.getList('boot.logging.stacktrace.filter.exclude');
// → ['dart:', 'package:shelf/']
```

## Conditional Beans

Use `@Requires` to load beans only when config is present:

```dart
@Singleton()
@Requires(property: 'pg.host')  // only loads if pg.host is set
class PgClient { ... }

@Singleton()
@Requires(env: ['prod'])  // only in production
class ProductionCache { ... }

@Singleton()
@Requires(notEnv: ['test'])  // everywhere except test
class RealEmailService { ... }
```

## All Boot Config Options

```yaml
boot:
  env: dev                              # Active environment

  static:
    enabled: false                      # Serve static files
    path: /static                       # URL prefix
    directory: public/                  # Filesystem directory
    index: index.html                   # Default file for directories
    cache:
      max-age: 3600                     # Cache-Control max-age (seconds)
      etag: true                        # Generate ETag headers
    gzip: true                          # Serve .gz variants

  logging:
    level: info                         # trace, debug, info, warn, error
    format: text                        # text or json
    request-logging: true               # Log incoming requests
    stacktrace:
      filter:
        enabled: true                   # Filter stack traces
        max-depth: 10                   # Max frames shown
        exclude:                        # Hide matching frames
          - dart:
          - package:shelf/
          - package:shelf_router/
        include: []                     # If set, ONLY show matching

  security:
    enabled: false
    default-access: isAuthenticated()
    intercept-url-map:
      - pattern: /api/**
        access: [isAuthenticated()]
      - pattern: /public/**
        access: [isAnonymous()]

  http:
    cors:
      enabled: false
      allowed-origins: ['*']
      allowed-methods: [GET, POST, PUT, DELETE]
      allowed-headers: [Content-Type, Authorization]
      max-age: 3600

  websocket:
    enabled: false
    max-frame-size: 65536
    ping-interval: 30s
    auth: true                          # Require auth on WebSocket upgrade

  server:
    ssl:
      enabled: false                    # Enable TLS
      cert: server.pem                  # Certificate file
      key: server-key.pem              # Private key file
      client-auth: none                 # none, optional, required (mTLS)
      trust-store: ca.pem              # CA for client cert validation
```

## Accessing Config Programmatically

```dart
@Singleton()
class MyService {
  final BootConfig _config;
  MyService(this._config);

  void doSomething() {
    final value = _config.get('myapp.feature-flag');
    final items = _config.getList('myapp.allowed-origins');
  }
}
```
