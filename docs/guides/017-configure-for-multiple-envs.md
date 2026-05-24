# Guide 017: Configure for Multiple Environments

## What you'll build

Configure your app differently for development, testing, and production — different databases, different log levels, different features enabled.

## What you'll learn

- How environment-specific YAML files work
- How to set the active environment
- How `@Requires` enables/disables beans per environment
- How environment variables override config
- How to test environment-specific behavior

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: How environments work

Boot loads config files in this order (later overrides earlier):

```
application.yml              ← always loaded (base config)
application-{env}.yml        ← loaded if boot.env matches
Environment variables        ← always override YAML
CLI arguments                ← highest priority
```

---

## Step 2: Create environment-specific files

**`application.yml`** — base config (shared by all environments):

```yaml
boot:
  env: dev
  logging:
    level: info

server:
  port: 8080

pg:
  database: todo_app
  username: postgres
  password: postgres
```

**`application-dev.yml`** — development overrides:

```yaml
pg:
  host: localhost
  port: 5432

boot:
  logging:
    level: debug
    request-logging: true
```

**`application-prod.yml`** — production overrides:

```yaml
pg:
  host: prod-db.internal
  port: 5432

boot:
  logging:
    level: warn
    format: json
    request-logging: true
  static:
    enabled: true
    cache:
      max-age: 86400
```

**`application-test.yml`** — test overrides:

```yaml
pg:
  host: localhost
  port: 5433
  database: todo_app_test

boot:
  logging:
    level: error
    request-logging: false
```

---

## Step 3: Set the active environment

Three ways (in priority order):

**1. Environment variable (recommended for production):**

```bash
BOOT_ENV=prod dart run bin/main.dart
```

**2. In application.yml:**

```yaml
boot:
  env: dev
```

**3. CLI argument:**

```bash
dart run bin/main.dart --boot.env=staging
```

---

## Step 4: Environment variables override YAML

Any config key can be overridden with an environment variable. The mapping:

```
pg.host       → PG_HOST
pg.port       → PG_PORT
boot.env      → BOOT_ENV
weather.api-key → WEATHER_API_KEY
```

Rule: replace `.` with `_`, replace `-` with `_`, uppercase.

```bash
# Override database host without changing any file
PG_HOST=10.0.0.5 PG_PORT=5433 boot serve
```

This is how you configure production without secrets in YAML files.

---

## Step 5: Conditional beans with @Requires

Load different beans in different environments:

```dart
/// Only loads in production — sends real emails.
@Singleton()
@Requires(env: ['prod'])
class SmtpEmailService implements EmailService {
  // Real SMTP implementation
}

/// Only loads in dev and test — logs instead of sending.
@Singleton()
@Requires(notEnv: ['prod'])
class FakeEmailService implements EmailService {
  @override
  Future<void> send(String to, String body) async {
    print('📧 [FAKE] Would send to $to: $body');
  }
}
```

**What's happening:**

- In production: `SmtpEmailService` loads, `FakeEmailService` doesn't
- In dev/test: `FakeEmailService` loads, `SmtpEmailService` doesn't
- Code that injects `EmailService` gets the right one automatically

---

## Step 6: Feature flags via config

```dart
@Singleton()
@Requires(property: 'features.new-dashboard', value: 'true')
class NewDashboardController { ... }
```

```yaml
# application-dev.yml — enable for testing
features:
  new-dashboard: true

# application-prod.yml — not yet in production
features:
  new-dashboard: false
```

---

## Step 7: Test environment-specific behavior

**`test/env_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Environment configuration', () {
    test('default test env loads FakeEmailService', () async {
      // bootTest defaults to env: 'test'
      await bootTest($configure, test: (client, container) async {
        final email = container.get<EmailService>();
        expect(email, isA<FakeEmailService>());
      });
    });

    test('prod env loads SmtpEmailService', () async {
      await bootTest($configure, env: 'prod', properties: {
        'pg.host': 'localhost', // still need DB for other beans
      }, test: (client, container) async {
        final email = container.get<EmailService>();
        expect(email, isA<SmtpEmailService>());
      });
    });

    test('feature flag controls bean loading', () async {
      await bootTest($configure, properties: {
        'features.new-dashboard': 'true',
      }, test: (client, container) async {
        expect(container.has<NewDashboardController>(), isTrue);
      });
    });

    test('feature flag disabled', () async {
      await bootTest($configure, properties: {
        'features.new-dashboard': 'false',
      }, test: (client, container) async {
        expect(container.has<NewDashboardController>(), isFalse);
      });
    });
  });
}
```

---

## Step 8: Docker and production

In Docker, set environment via `docker-compose.yml`:

```yaml
services:
  app:
    build: .
    environment:
      BOOT_ENV: prod
      PG_HOST: postgres
      PG_PORT: 5432
      PG_PASSWORD: ${DB_PASSWORD}  # from .env file
      WEATHER_API_KEY: ${WEATHER_KEY}
    depends_on:
      - postgres
```

No secrets in YAML files. No config files to manage per deployment.

---

## Step 9: Summary of config resolution

For a key like `pg.host`:

| Source | Priority | Example |
|---|---|---|
| CLI argument | Highest | `--pg.host=10.0.0.5` |
| Environment variable | High | `PG_HOST=10.0.0.5` |
| `application-prod.yml` | Medium | `pg: host: prod-db.internal` |
| `application.yml` | Lowest | `pg: host: localhost` |

First match wins (highest priority).

---

## What you've learned

- `application-{env}.yml` overrides base config per environment
- Set env with `BOOT_ENV`, `boot.env` in YAML, or `--boot.env=` CLI arg
- Environment variables override YAML (for secrets in production)
- `@Requires(env: ['prod'])` loads beans only in specific environments
- `@Requires(property: 'key', value: 'val')` enables feature flags
- `bootTest` defaults to `test` environment
- Docker uses env vars — no config files in containers

## Next steps

- [Guide 018: mTLS IoT Server](018-mtls-iot-server.md)
