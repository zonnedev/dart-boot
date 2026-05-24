# Dependency Injection

Compile-time DI — all wiring resolved at build time, zero reflection.

## Defining Beans

Any class annotated with `@Singleton()` becomes a managed bean:

```dart
import 'package:boot/boot.dart';
part 'user_repository.g.dart';

@Singleton()
class UserRepository {
  final _users = <String, User>{};

  Future<User?> findById(String id) async => _users[id];
  Future<List<User>> findAll() async => _users.values.toList();
  Future<User> save(User user) async {
    _users[user.id] = user;
    return user;
  }
}
```

**Test:**
```dart
test('UserRepository is a singleton', () async {
  await bootTest($configure, test: (client, container) async {
    final repo1 = container.get<UserRepository>();
    final repo2 = container.get<UserRepository>();
    expect(identical(repo1, repo2), isTrue); // same instance
  });
});
```

## Constructor Injection

Dependencies are injected via the constructor automatically:

```dart
@Singleton()
class UserService {
  final UserRepository _repo;
  final EmailService _email;

  UserService(this._repo, this._email); // both injected by the container
  
  Future<User> createUser(String name, String email) async {
    final user = User(id: generateId(), name: name, email: email);
    await _repo.save(user);
    await _email.sendWelcome(user);
    return user;
  }
}
```

**Test:**
```dart
test('UserService gets dependencies injected', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<UserService>();
    expect(service, isNotNull);
    // Dependencies were injected automatically
  });
});

test('UserService with mocked email', () async {
  await bootTest($configure, overrides: (c) {
    c.override<EmailService>(FakeEmailService());
  }, test: (client, container) async {
    final service = container.get<UserService>();
    final user = await service.createUser('Alice', 'alice@test.com');
    expect(user.name, 'Alice');
    // FakeEmailService was used instead of real one
  });
});
```

## @Prototype — New Instance Each Time

```dart
@Prototype()
class RequestContext {
  final String id = generateId();
}
```

**Test:**
```dart
test('Prototype creates new instance each time', () async {
  await bootTest($configure, test: (client, container) async {
    final ctx1 = container.get<RequestContext>();
    final ctx2 = container.get<RequestContext>();
    expect(identical(ctx1, ctx2), isFalse); // different instances
    expect(ctx1.id, isNot(ctx2.id));
  });
});
```

## @Factory — Producing Multiple Beans

A factory class produces beans via annotated methods:

```dart
@Factory()
class DataSourceFactory {
  final BootConfig _config;
  DataSourceFactory(this._config);

  @Singleton()
  @Named('primary')
  DataSource primaryDb() => DataSource(
    host: _config.get('db.primary.host')!,
    port: int.parse(_config.get('db.primary.port') ?? '5432'),
  );

  @Singleton()
  @Named('analytics')
  DataSource analyticsDb() => DataSource(
    host: _config.get('db.analytics.host')!,
    port: int.parse(_config.get('db.analytics.port') ?? '5432'),
  );
}
```

**Test:**
```dart
test('Factory produces named beans', () async {
  await bootTest($configure, properties: {
    'db.primary.host': 'primary.db.local',
    'db.analytics.host': 'analytics.db.local',
  }, test: (client, container) async {
    final primary = container.getNamed<DataSource>('primary');
    final analytics = container.getNamed<DataSource>('analytics');
    expect(primary.host, 'primary.db.local');
    expect(analytics.host, 'analytics.db.local');
  });
});
```

## @Named — Multiple Beans of Same Type

When multiple beans implement the same interface, use `@Named` to distinguish:

```dart
abstract class Cache {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

@Singleton()
@Named()  // auto-derives: 'memoryCache'
class MemoryCache implements Cache {
  final _store = <String, String>{};
  @override
  Future<String?> get(String key) async => _store[key];
  @override
  Future<void> set(String key, String value) async => _store[key] = value;
}

@Singleton()
@Named('redis')
class RedisCache implements Cache {
  final RedisClient _client;
  RedisCache(this._client);
  @override
  Future<String?> get(String key) async => _client.get(key);
  @override
  Future<void> set(String key, String value) async => _client.set(key, value);
}
```

Inject by name:

```dart
@Singleton()
class SessionService {
  final Cache _cache;
  SessionService(@Named('redis') this._cache); // gets RedisCache
}
```

**Test:**
```dart
test('Named beans resolve correctly', () async {
  await bootTest($configure, properties: {
    'redis.host': 'localhost',
  }, test: (client, container) async {
    final memory = container.getNamed<Cache>('memoryCache');
    final redis = container.getNamed<Cache>('redis');
    expect(memory, isA<MemoryCache>());
    expect(redis, isA<RedisCache>());
  });
});
```

## @Primary — Default When Multiple Exist

```dart
@Singleton()
@Primary()
class MemoryCache implements Cache { ... }  // wins when injecting Cache

@Singleton()
@Named('redis')
class RedisCache implements Cache { ... }
```

```dart
@Singleton()
class ProductService {
  final Cache _cache;
  ProductService(this._cache); // gets MemoryCache (@Primary)
}
```

**Test:**
```dart
test('Primary bean wins without qualifier', () async {
  await bootTest($configure, test: (client, container) async {
    final cache = container.get<Cache>();
    expect(cache, isA<MemoryCache>()); // @Primary wins
  });
});
```

## Auto-Interface Registration

Beans are automatically registered under their implemented interfaces:

```dart
@Singleton()
class PostgresUserRepo implements UserRepository { ... }
```

This registers under `UserRepository` automatically — no `typed:` annotation needed. The generator detects `implements UserRepository` from the AST.

**Test:**
```dart
test('Bean registered under interface', () async {
  await bootTest($configure, test: (client, container) async {
    final repo = container.get<UserRepository>();
    expect(repo, isA<PostgresUserRepo>());
  });
});
```

## @Replaces — Overriding Beans

Replace a bean from a library or another module:

```dart
@Singleton()
@Replaces(PostgresUserRepo)
class InMemoryUserRepo implements UserRepository {
  final _store = <String, User>{};
  @override
  Future<User?> findById(String id) async => _store[id];
  @override
  Future<List<User>> findAll() async => _store.values.toList();
  @override
  Future<User> save(User user) async { _store[user.id] = user; return user; }
}
```

**Test:**
```dart
test('Replaces overrides the original bean', () async {
  await bootTest($configure, test: (client, container) async {
    final repo = container.get<UserRepository>();
    expect(repo, isA<InMemoryUserRepo>()); // replaced
  });
});
```

## @Requires — Conditional Beans

Beans load only when conditions are met:

```dart
@Singleton()
@Requires(property: 'redis.host')  // only if redis.host is configured
class RedisClient { ... }

@Singleton()
@Requires(env: ['prod', 'staging'])  // only in prod/staging
class DatadogMetrics { ... }

@Singleton()
@Requires(notEnv: ['test'])  // everywhere except test
class RealEmailService { ... }
```

**Test:**
```dart
test('Conditional bean loads when property is set', () async {
  await bootTest($configure, properties: {
    'redis.host': 'localhost',
  }, test: (client, container) async {
    expect(container.has<RedisClient>(), isTrue);
  });
});

test('Conditional bean does NOT load without property', () async {
  await bootTest($configure, test: (client, container) async {
    expect(container.has<RedisClient>(), isFalse);
  });
});
```

## @Value — Configuration Injection

Inject values from `application.yml`:

```dart
@Singleton()
class EmailService {
  final String _smtpHost;
  final int _smtpPort;
  final String _from;

  EmailService(
    @Value('\${email.smtp.host}') this._smtpHost,
    @Value('\${email.smtp.port:587}') this._smtpPort,  // default: 587
    @Value('\${email.from:noreply@app.com}') this._from,
  );
}
```

```yaml
# application.yml
email:
  smtp:
    host: smtp.gmail.com
    port: 465
  from: hello@myapp.com
```

**Test:**
```dart
test('Value injection from config', () async {
  await bootTest($configure, properties: {
    'email.smtp.host': 'test-smtp.local',
    'email.smtp.port': '25',
  }, test: (client, container) async {
    final service = container.get<EmailService>();
    // service._smtpHost == 'test-smtp.local'
    // service._smtpPort == 25
  });
});
```

## Lifecycle Hooks

```dart
@Singleton()
class DatabasePool {
  late final Pool _pool;

  @PostConstruct()
  void init() {
    _pool = Pool(maxConnections: 10);
    print('Pool initialized');
  }

  @PreDestroy()
  void close() {
    _pool.close();
    print('Pool closed');
  }
}
```

**Test:**
```dart
test('PostConstruct runs on creation', () async {
  await bootTest($configure, properties: {
    'pg.host': 'localhost',
  }, test: (client, container) async {
    final pool = container.get<DatabasePool>();
    // @PostConstruct already ran — pool is initialized
    expect(pool, isNotNull);
  });
});
```

## getAll — Collecting All Beans of a Type

```dart
@Singleton()
class NotificationDispatcher {
  final List<NotificationChannel> _channels;

  NotificationDispatcher(BeanContainer container)
      : _channels = container.getAll<NotificationChannel>();

  Future<void> notify(String message) async {
    for (final channel in _channels) {
      await channel.send(message);
    }
  }
}
```

**Test:**
```dart
test('getAll returns all implementations', () async {
  await bootTest($configure, test: (client, container) async {
    final channels = container.getAll<NotificationChannel>();
    expect(channels.length, greaterThanOrEqualTo(2)); // email + sms + push
  });
});
```

## Compile-Time Ambiguity Check

If two beans of the same type exist with no `@Named`, no `@Primary`, and no `@Replaces`, the build fails:

```
╔══════════════════════════════════════════════════════════════
║ AMBIGUOUS BEAN
║
║ Multiple beans of type "Cache" with no qualifier:
║   $MemoryCacheDefinition, $RedisCacheDefinition
║
║ Fix: Add @Primary to one, @Named to differentiate, or
║ @Replaces to explicitly override.
╚══════════════════════════════════════════════════════════════
```

This is caught at **build time** — you'll never get a runtime ambiguity error for provable conflicts.

## Summary

| Annotation | Purpose |
|---|---|
| `@Singleton()` | One instance, shared |
| `@Prototype()` | New instance per injection |
| `@Factory()` | Class that produces beans via methods |
| `@Named('x')` | Qualifier for multiple beans of same type |
| `@Named()` | Auto-derives name from class name |
| `@Primary()` | Default when multiple candidates |
| `@Replaces(Type)` | Explicitly override another bean |
| `@Requires(...)` | Conditional loading |
| `@Value('\${key:default}')` | Config injection |
| `@PostConstruct()` | Run after creation |
| `@PreDestroy()` | Run before shutdown |
