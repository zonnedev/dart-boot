# Writing Boot Libraries

Boot libraries are Dart packages that provide beans, controllers, interceptors, or other components to Boot applications. Libraries use the same annotations as application code and ship pre-built wiring via a generated module function.

## Quick Start

```yaml
# pubspec.yaml
name: boot_redis
version: 1.0.0

dependencies:
  boot_core: ^0.1.0

dev_dependencies:
  boot_generator: ^0.1.0
  build_runner: ^2.4.0
```

Mark your barrel file with `@BootLibrary()`:

```dart
// lib/boot_redis.dart
@BootLibrary()
library boot_redis;

import 'package:boot_core/boot_core.dart';

export 'src/redis_client.dart';
export 'src/generated/boot_module.g.dart';
```

Write beans normally:

```dart
// lib/src/redis_client.dart
import 'package:boot_core/boot_core.dart';
part 'redis_client.g.dart';

@Singleton()
@Requires(property: 'redis.host')
class RedisClient {
  final String _host;
  final int _port;

  RedisClient(
    @Value('\${redis.host}') this._host,
    @Value('\${redis.port:6379}') this._port,
  );

  Future<String> get(String key) async { ... }
}
```

Build:

```bash
dart run build_runner build
```

This generates:
- `.g.dart` files — bean definitions, route classes, etc.
- `lib/src/generated/boot_module.g.dart` — the module function that wires all your beans

Publish:

```bash
dart pub publish  # Include all generated files
```

## How It Works

### The `@BootLibrary` Annotation

The `@BootLibrary()` annotation on your barrel file tells consuming apps that this package is a Boot library. It's a simple marker — no parameters needed.

### The Module Function

When you build a `@BootLibrary` package, the generator produces a self-contained module function:

```dart
// lib/src/generated/boot_module.g.dart (generated)
void $BootRedisModule(BeanContainer container, BootRouter router, BootConfig config) {
  if (config.get('redis.host') != null) {
    container.register<RedisClient>($RedisClientDefinition());
  }
}
```

This function:
- Registers all beans (including internal ones not in the public API)
- Bakes in `@Requires` conditions at generation time
- Registers routes, interceptors, exception handlers, health indicators
- Is completely self-contained — no source re-analysis needed by the app

### App-Side Discovery

When an app depends on your library:

1. App runs `boot build`
2. The context builder finds `@BootLibrary` on your barrel file
3. It imports and calls your module function in the app's `$configure()`
4. Your beans participate in DI, AOP, config, events — everything

**No configuration needed by the app developer** — just add the dependency.

The generated app code looks like:

```dart
void $configure(BeanContainer container, BootRouter router) {
  final config = container.get<BootConfig>();

  // Library modules loaded first
  $BootRedisModule(container, router, config);

  // App's own beans registered after
  container.register<MyService>($MyServiceDefinition());
}
```

## What Libraries Can Provide

### Beans

```dart
@Singleton()
class RedisClient { ... }

@Singleton()
@Named('redis')
class RedisCacheService implements CacheService { ... }
```

### Controllers

```dart
@Controller('/health/redis')
class RedisHealthController {
  final RedisClient _redis;
  RedisHealthController(this._redis);

  @Get('/')
  Future<Response> health(Request req) async {
    final ok = await _redis.ping();
    return ok ? Response.ok('UP') : Response.error('DOWN');
  }
}
```

### AOP Interceptors

```dart
@Around()
class Cached { const Cached(); }

@Singleton()
@InterceptorBean(Cached)
class CacheInterceptor implements MethodInterceptor {
  final RedisClient _redis;
  CacheInterceptor(this._redis);

  @override
  dynamic intercept(InvocationContext ctx) {
    final key = '${ctx.methodName}:${ctx.args}';
    final cached = _redis.get(key);
    if (cached != null) return cached;
    final result = ctx.proceed();
    _redis.set(key, result);
    return result;
  }
}
```

### Event Listeners

```dart
@Singleton()
class RedisConnectionMonitor {
  @EventListener()
  void onStartup(StartupEvent event) { ... }

  @EventListener()
  void onShutdown(ShutdownEvent event) { ... }
}
```

### Exception Handlers

```dart
@Singleton()
class RedisExceptionHandler implements ExceptionHandler<RedisException> {
  @override
  Response handle(Request req, RedisException e) {
    return Response.error('Redis unavailable');
  }
}
```

### Health Indicators

```dart
@Singleton()
class RedisHealth implements HealthIndicator {
  final RedisClient _redis;
  RedisHealth(this._redis);

  @override
  Future<HealthResult> check() async { ... }
}
```

## Internal Beans

Libraries often have internal implementation beans that shouldn't be part of the public API. In Dart, `lib/src/` files are private by convention but must be exported for the scanner to see them during the library's own build.

However, with the module function architecture, **internal beans work without being exported from the barrel**:

1. The library's own `build_runner` can see all files in its `lib/` (including `lib/src/`)
2. The module function is generated with registrations for ALL beans — internal and public
3. The app only calls the module function — it never analyzes library source
4. Internal beans are registered in the container but users can't reference the type

```dart
// lib/src/connection_pool.dart (NOT exported from barrel)
@Singleton()
class ConnectionPool { ... }

// lib/src/redis_client.dart (exported from barrel)
@Singleton()
@Requires(property: 'redis.host')
class RedisClient {
  final ConnectionPool _pool;  // injected internally
  RedisClient(this._pool);
}
```

The generated module function registers both:

```dart
void $BootRedisModule(BeanContainer container, BootRouter router, BootConfig config) {
  if (config.get('redis.host') != null) {
    container.register<ConnectionPool>($ConnectionPoolDefinition());
    container.register<RedisClient>($RedisClientDefinition());
  }
}
```

Users can inject `RedisClient` but cannot inject `ConnectionPool` — they can't reference the type since it's not exported.

## Conditional Beans — Self-Disabling Libraries

Libraries should use `@Requires` so they don't break apps that don't configure them:

```dart
@Singleton()
@Requires(property: 'redis.host')  // Only loads if configured
class RedisClient { ... }

@Singleton()
@Requires(notEnv: ['test'])
class RedisConnectionPool { ... }
```

These conditions are baked into the module function at library build time. If `redis.host` isn't set, the module function simply skips registration — no errors.

## App Developer Experience

```yaml
# pubspec.yaml
dependencies:
  boot_redis: ^1.0.0
```

```yaml
# application.yml
redis:
  host: localhost
```

```bash
boot serve  # RedisClient is available, health endpoint works, @Cached works
```

No `@Import`, no manual wiring, no configuration beyond what the library needs.

## Controlling Which Libraries Load

By default, all packages with `@BootLibrary` are auto-discovered. To limit:

```dart
@BootApplication(scan: ['boot_redis'])  // Only load boot_redis
class App {}
```

Without `scan`, all `@BootLibrary` dependencies are loaded.

## Overriding Library Beans

App developers can replace public library beans:

```dart
@Singleton()
@Replaces(RedisClient)
class MockRedisClient extends RedisClient { ... }
```

This works because the app's beans are registered **after** library modules, so `@Replaces` overwrites the library's registration.

Internal beans (not exported from the barrel) cannot be replaced — users can't reference the type.

To disable a library entirely, simply don't configure its required properties:

```yaml
# Don't set redis.host → nothing from boot_redis loads
```

## Library Project Structure

```
boot_redis/
├── lib/
│   ├── boot_redis.dart                # @BootLibrary barrel — exports public API + module
│   └── src/
│       ├── redis_client.dart          # @Singleton (public)
│       ├── redis_client.g.dart        # Generated definition
│       ├── connection_pool.dart       # @Singleton (internal — not exported)
│       ├── connection_pool.g.dart     # Generated definition
│       ├── cache_interceptor.dart
│       ├── cache_interceptor.g.dart
│       ├── health_controller.dart
│       └── generated/
│           ├── boot_module.g.dart     # Generated module function
│           └── boot_context.g.dart    # Generated context (for library's own tests)
├── pubspec.yaml
├── build.yaml
└── test/
    └── redis_test.dart
```

**Important:** Commit all `.g.dart` files to source control. These are shipped with your package so apps don't need to re-generate them.

## build.yaml

Libraries need a minimal `build.yaml`:

```yaml
targets:
  $default:
    builders:
      boot_generator|context_builder:
        enabled: true
```

## Testing Your Library

Test your beans in isolation using the generated `boot_context.g.dart`:

```dart
import 'package:boot_test/boot_test.dart';
import 'package:boot_redis/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('RedisClient connects', () async {
    await bootTest($configure, properties: {
      'redis.host': 'localhost',
    }, test: (client, container) async {
      final redis = container.get<RedisClient>();
      expect(redis, isNotNull);
    });
  });
}
```

## Library Development Workflow

1. Write your beans with standard Boot annotations
2. Run `dart run build_runner build` to generate definitions + module function
3. Export public types and `boot_module.g.dart` from your barrel file
4. Commit generated files
5. Publish to pub.dev

When a user adds your library as a dependency and runs their build, the framework automatically discovers `@BootLibrary`, imports your module function, and calls it during app startup.

## Summary

| Concern | How it's handled |
|---------|-----------------|
| Discovery | `@BootLibrary` on barrel file |
| Wiring | Generated `$<Package>Module()` function |
| Conditions | `@Requires` baked into module function |
| Internal beans | Registered by module, invisible to users |
| Overrides | `@Replaces` in app code (runs after modules) |
| Disabling | Don't set required properties |
| Ordering | Library modules load before app beans |
