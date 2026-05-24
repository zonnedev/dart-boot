# Guide 015: Create a Library

## What you'll build

A reusable `boot_cache` library that provides an in-memory cache bean to any Boot application. Other developers add your library as a dependency and the cache is available automatically.

## What you'll learn

- How to scaffold a Boot library
- What `@BootLibrary` does
- How module functions work
- How internal beans stay hidden from users
- How to test your library in isolation
- How to publish and consume your library

## Prerequisites

- Understanding of Boot DI ([Guide 005](005-use-dependency-injection.md))

---

## Step 1: What is a Boot library?

A Boot library is a Dart package that provides beans to Boot applications. When an app adds your library as a dependency, your beans are automatically discovered and registered — no configuration needed by the app developer.

Examples: a Redis client, a PostgreSQL pool, a metrics collector, an auth provider.

---

## Step 2: Scaffold the library

```bash
boot create library boot_cache
cd boot_cache
dart pub get
```

This creates:

```
boot_cache/
├── lib/
│   ├── boot_cache.dart              ← barrel file with @BootLibrary
│   └── src/
│       ├── boot_cache_client.dart   ← example bean
│       └── generated/
│           └── boot_module.g.dart   ← generated (after build)
├── test/
├── pubspec.yaml
├── build.yaml
└── README.md
```

---

## Step 3: Understand the barrel file

**`lib/boot_cache.dart`**

```dart
@BootLibrary()
library boot_cache;

import 'package:boot_core/boot_core.dart';

export 'src/cache_service.dart';
export 'src/generated/boot_module.g.dart';
```

**What's happening:**

- `@BootLibrary()` — tells consuming apps "this package is a Boot library, call my module function"
- `export 'src/cache_service.dart'` — makes the public API visible to users
- `export 'src/generated/boot_module.g.dart'` — exposes the generated wiring function

---

## Step 4: Write the public bean

This is what users will inject in their apps:

**`lib/src/cache_service.dart`**

```dart
import 'package:boot_core/boot_core.dart';

part 'cache_service.g.dart';

/// A simple in-memory cache with TTL support.
/// Activate by setting `cache.enabled: true` in application.yml.
@Singleton()
@Requires(property: 'cache.enabled', value: 'true')
class CacheService {
  final int _maxSize;
  final _store = <String, _CacheEntry>{};

  CacheService(@Value('\${cache.max-size:1000}') this._maxSize);

  /// Get a value from the cache. Returns null if not found or expired.
  String? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Store a value with a time-to-live.
  void set(String key, String value, {Duration ttl = const Duration(minutes: 5)}) {
    if (_store.length >= _maxSize) _evictOldest();
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  /// Remove a value.
  void remove(String key) => _store.remove(key);

  /// Clear all cached values.
  void clear() => _store.clear();

  /// Number of items currently cached.
  int get size => _store.length;

  void _evictOldest() {
    if (_store.isEmpty) return;
    _store.remove(_store.keys.first);
  }
}

class _CacheEntry {
  final String value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

**What's happening:**

- `@Requires(property: 'cache.enabled', value: 'true')` — the bean only loads if the app configures it. Apps that don't set `cache.enabled: true` won't have this bean — no errors, no wasted resources.
- `@Value('\${cache.max-size:1000}')` — configurable max cache size, defaults to 1000.
- `_CacheEntry` is private — users can't see or use it. It's an implementation detail.

---

## Step 5: Add an internal bean (not visible to users)

Libraries often have internal helpers. These get registered in the container but users can't reference the type.

**`lib/src/cache_cleanup_job.dart`**

```dart
import 'package:boot_core/boot_core.dart';
import 'cache_service.dart';

part 'cache_cleanup_job.g.dart';

/// Internal: cleans expired entries periodically.
/// NOT exported from the barrel — users can't inject this directly.
@Singleton()
@Requires(property: 'cache.enabled', value: 'true')
class CacheCleanupJob {
  final CacheService _cache;
  static final _log = Logger('CacheCleanupJob');

  CacheCleanupJob(this._cache);

  @Scheduled(fixedRate: '1m')
  void cleanExpired() {
    _log.debug('Running cache cleanup');
    // The cache self-evicts on read, but this catches entries nobody reads
  }
}
```

**Important:** This file is NOT exported from `boot_cache.dart`. Users can't import it or inject `CacheCleanupJob`. But the module function still registers it — it runs silently in the background.

---

## Step 6: Build the library

```bash
boot build
```

This generates:
- `lib/src/cache_service.g.dart` — the `$CacheServiceDefinition`
- `lib/src/cache_cleanup_job.g.dart` — the `$CacheCleanupJobDefinition`
- `lib/src/generated/boot_module.g.dart` — the module function

The module function looks like:

```dart
// Generated — registers ALL beans (public + internal)
bool _$BootCacheModuleLoaded = false;
void $BootCacheModule(BeanContainer container, BootRouter router, BootConfig config) {
  if (_$BootCacheModuleLoaded) return;
  _$BootCacheModuleLoaded = true;

  if (config.get('cache.enabled') == 'true') {
    container.register<CacheService>($CacheServiceDefinition());
    container.register<CacheCleanupJob>($CacheCleanupJobDefinition());
  }
}
```

Notice:
- `_loaded` flag prevents duplicate registration
- `@Requires` conditions are baked in
- Both public AND internal beans are registered

---

## Step 7: Test the library

**`test/cache_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:boot_cache/src/generated/boot_context.g.dart';
import 'package:boot_cache/src/cache_service.dart';
import 'package:test/test.dart';

void main() {
  group('CacheService', () {
    test('loads when cache.enabled is true', () async {
      await bootTest($configure, properties: {
        'cache.enabled': 'true',
      }, test: (client, container) async {
        expect(container.has<CacheService>(), isTrue);
      });
    });

    test('does NOT load without config', () async {
      await bootTest($configure, test: (client, container) async {
        expect(container.has<CacheService>(), isFalse);
      });
    });

    test('set and get', () async {
      await bootTest($configure, properties: {
        'cache.enabled': 'true',
      }, test: (client, container) async {
        final cache = container.get<CacheService>();
        cache.set('key', 'value');
        expect(cache.get('key'), 'value');
      });
    });

    test('expired entries return null', () async {
      await bootTest($configure, properties: {
        'cache.enabled': 'true',
      }, test: (client, container) async {
        final cache = container.get<CacheService>();
        cache.set('key', 'value', ttl: Duration(milliseconds: 1));
        await Future.delayed(Duration(milliseconds: 10));
        expect(cache.get('key'), isNull);
      });
    });

    test('respects max size', () async {
      await bootTest($configure, properties: {
        'cache.enabled': 'true',
        'cache.max-size': '3',
      }, test: (client, container) async {
        final cache = container.get<CacheService>();
        cache.set('a', '1');
        cache.set('b', '2');
        cache.set('c', '3');
        cache.set('d', '4'); // evicts oldest
        expect(cache.size, 3);
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 8: Publish

Commit the generated files and publish:

```bash
# Make sure all .g.dart files are committed
git add .
git commit -m "Initial release"

# Publish to local registry (or pub.dev)
dart pub publish
```

---

## Step 9: Consume the library in an app

In the app's `pubspec.yaml`:

```yaml
dependencies:
  boot: ^0.1.0
  boot_cache: ^0.1.0
```

In the app's `application.yml`:

```yaml
cache:
  enabled: true
  max-size: 500
```

In the app's code:

```dart
@Singleton()
class ProductService {
  final CacheService _cache;  // injected from boot_cache library!
  ProductService(this._cache);

  Future<Product> getProduct(String id) async {
    final cached = _cache.get('product:$id');
    if (cached != null) return Product.fromJson(jsonDecode(cached));

    final product = await _repo.findById(id);
    _cache.set('product:$id', jsonEncode(product.toJson()));
    return product;
  }
}
```

**The app developer did nothing special** — just added the dependency and configured it. Boot discovered `@BootLibrary`, called `$BootCacheModule`, and `CacheService` was available for injection.

---

## Step 10: Override library beans

App developers can replace your bean:

```dart
@Singleton()
@Replaces(CacheService)
class RedisCacheService extends CacheService {
  // Use Redis instead of in-memory
}
```

Or disable it entirely by not setting `cache.enabled: true`.

---

## Library checklist

Before publishing:

- [ ] `@BootLibrary()` on barrel file
- [ ] `export 'src/generated/boot_module.g.dart'` in barrel
- [ ] `@Requires` on beans so they don't break apps that don't configure them
- [ ] `@Value` with defaults for all config values
- [ ] All `.g.dart` files committed
- [ ] Tests pass
- [ ] README explains what config is needed

---

## What you've learned

- `boot create library` scaffolds the structure
- `@BootLibrary()` marks the package for auto-discovery
- The module function registers all beans (public + internal)
- `@Requires` makes beans conditional — libraries never break apps
- Internal beans (not exported) are invisible to users but still work
- `_loaded` flag prevents duplicate registration from transitive deps
- Users just add the dependency + config — everything wires automatically
- `@Replaces` lets users swap your implementation

## Next steps

- [Guide 016: Consume External APIs](016-consume-external-apis.md) — use `@Client` to call other services
