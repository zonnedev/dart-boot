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

---

## @ConfigurationProperties — Type-Safe Config Beans

`@ConfigurationProperties` creates a singleton bean whose constructor parameters are automatically bound from config using the specified prefix.

### Definition

```dart
import 'package:boot_core/boot_core.dart';

@ConfigurationProperties('boot.http.client')
class HttpClientConfig {
  final Duration connectTimeout;
  final Duration readTimeout;
  final int maxRedirects;

  HttpClientConfig({
    this.connectTimeout = const Duration(seconds: 5),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
  });
}
```

### Configuration

```yaml
boot:
  http:
    client:
      connect-timeout: 10s
      read-timeout: 60s
      max-redirects: 3
```

### Result

A singleton `HttpClientConfig` bean is registered with values from config (or constructor defaults if absent).

### Usage

Inject it like any other bean:

```dart
@Singleton()
class MyService {
  final HttpClientConfig _config;
  MyService(this._config);

  void printTimeout() => print(_config.connectTimeout);
}
```

Or use it in a `@Factory`:

```dart
@Factory()
class HttpClientFactory {
  @Singleton()
  HttpClient httpClient(HttpClientConfig config) =>
    HttpClientBuilder(
      connectTimeout: config.connectTimeout,
      readTimeout: config.readTimeout,
      maxRedirects: config.maxRedirects,
    ).build();
}
```

### Field Mapping

Constructor parameter names are converted from camelCase to kebab-case:

| Parameter | Config Key |
|-----------|-----------|
| `connectTimeout` | `connect-timeout` |
| `readTimeout` | `read-timeout` |
| `maxRedirects` | `max-redirects` |

### Supported Types

| Dart Type | Config Format | Example |
|-----------|--------------|---------|
| `String` | Plain text | `localhost` |
| `int` | Integer | `5` |
| `double` | Decimal | `0.5` |
| `bool` | `true`/`false` | `true` |
| `Duration` | Duration string | `5s`, `500ms`, `2m` |

### Difference from @EachProperty

| | `@ConfigurationProperties` | `@EachProperty` |
|---|---|---|
| Instances | One singleton | One per config sub-key |
| Naming | Not named | `@Named` per key |
| Use case | Global config | Multi-instance config |

---

## @EachProperty — Multi-Instance Config Beans

`@EachProperty` creates one named bean per config sub-key. Use it for services, database pools, cache regions — anything with multiple named instances.

### Definition

```dart
import 'package:boot_core/boot_core.dart';

@EachProperty('boot.http.client.services')
class HttpClientServiceConfig {
  final String url;
  final Duration connectTimeout;
  final Duration readTimeout;
  final int maxRedirects;

  HttpClientServiceConfig({
    this.url = '',
    this.connectTimeout = const Duration(seconds: 5),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
  });
}
```

### Configuration

```yaml
boot:
  http:
    client:
      services:
        github:
          url: https://api.github.com
          connect-timeout: 10s
        stripe:
          url: https://api.stripe.com
          read-timeout: 60s
          max-redirects: 3
```

### Result

Two named beans are registered automatically:
- `@Named('github') HttpClientServiceConfig` — url=https://api.github.com, connectTimeout=10s
- `@Named('stripe') HttpClientServiceConfig` — url=https://api.stripe.com, readTimeout=60s, maxRedirects=3

### Usage

```dart
@Singleton()
class PaymentService {
  final HttpClientServiceConfig _config;
  PaymentService(@Named('stripe') this._config);

  HttpClient get client => HttpClientBuilder.fromConfig(_config).build();
}
```

### Field Mapping

Constructor parameter names are converted from camelCase to kebab-case for config lookup:

| Field | Config Key |
|-------|-----------|
| `url` | `url` |
| `connectTimeout` | `connect-timeout` |
| `readTimeout` | `read-timeout` |
| `maxRedirects` | `max-redirects` |

### Supported Types

| Dart Type | Config Format | Example |
|-----------|--------------|---------|
| `String` | Plain text | `https://api.github.com` |
| `int` | Integer | `5` |
| `double` | Decimal | `0.5` |
| `bool` | `true`/`false` | `true` |
| `Duration` | Duration string | `5s`, `500ms`, `2m` |

---

## Duration Values

Many config options accept duration strings. The format is `<number><unit>`:

| Unit | Meaning | Example |
|------|---------|---------|
| `ms` | Milliseconds | `500ms` |
| `s` | Seconds | `5s` |
| `m` | Minutes | `2m` |
| `h` | Hours | `1h` |
| `d` | Days | `7d` |

```yaml
boot:
  http:
    client:
      connect-timeout: 5s
      read-timeout: 30s
  websocket:
    ping-interval: 30s
  test:
    timeout: 5s
    integration-timeout: 15s
```

### Parsing in Code

Use `parseDuration` and `parseDurationOrNull` from `boot_core`:

```dart
import 'package:boot_core/boot_core.dart';

// Throws FormatException on invalid input
final timeout = parseDuration('5s'); // Duration(seconds: 5)

// Returns null if input is null/empty, throws on invalid format
final optional = parseDurationOrNull(config.get('my.timeout')); // Duration? 
final withDefault = parseDurationOrNull(config.get('my.timeout')) ?? Duration(seconds: 10);
```

Invalid values (e.g., `timeout: abc`) throw a `FormatException` at startup — fail fast rather than silently using defaults.
