# Testing

Boot provides two test modes:

| | `bootTest` | `bootIntegrationTest` |
|---|---|---|
| **Server** | None — in-memory function calls | Real HTTP server on random port |
| **Speed** | Milliseconds | ~50ms startup |
| **HTTP** | Simulated via shelf handler | Real `dart:io` connections |
| **WebSocket** | Simulated in-memory channel | Real TCP WebSocket |
| **Isolation** | Full — fresh container per test | Full — fresh server per test |
| **Use for** | Controllers, filters, security, DI, serialization | WebSocket flows, TLS, streaming, multi-client |

Both modes run the same `configureRuntime` as production — filters, security, events, scheduling all execute identically.

For feature lifecycle tests (create → update → delete) that share a running server across a group, use `BootIntegrationTestApp`.

## Setup

```yaml
# pubspec.yaml
dev_dependencies:
  boot_test: ^0.1.0
  boot_generator: ^0.1.0
  build_runner: ^2.4.0
  test: ^1.25.0
```

Make sure you've run `boot build` before running tests — the generated `boot_context.g.dart` must exist.

---

## How It Works

`bootTest()` creates a fresh `BeanContainer`, registers all beans via `$configure`, then gives you an in-memory HTTP client that routes requests through the same pipeline as a real server (filters, security, exception handlers) — but without network I/O.

Each `bootTest()` call is fully isolated. Beans are created fresh, no state leaks between tests.

---

## bootTest() API

```dart
Future<void> bootTest(
  BootContextRegistrar configure,  // Your generated $configure function
  {
    String env = 'test',           // Active environment
    Map<String, String>? properties, // Config overrides
    void Function(TestContainer container)? overrides, // Bean overrides
    required Future<void> Function(TestClient client, BeanContainer container) test,
  }
)
```

---

## Your First Test

```dart
import 'package:boot_test/boot_test.dart';
import 'package:myapp/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('GET /hello returns greeting', () async {
    await bootTest($configure, test: (client, container) async {
      final res = await client.get('/hello/');
      res.expectStatus(200);
      expect(res.json()['message'], 'Hello from Boot!');
    });
  });
}
```

---

## TestClient — Making Requests

The `client` simulates HTTP requests without network:

### GET

```dart
final res = await client.get('/users/');
final res = await client.get('/users/42');
final res = await client.get('/search?q=alice&page=2');
```

### POST

```dart
// JSON body (default content-type: application/json)
final res = await client.post('/users/', body: {
  'name': 'Alice',
  'email': 'alice@example.com',
});

// Raw string body
final res = await client.post('/webhook', 
  body: 'raw payload',
  headers: {'content-type': 'text/plain'},
);
```

### PUT

```dart
final res = await client.put('/users/42', body: {
  'name': 'Updated Name',
});
```

### DELETE

```dart
final res = await client.delete('/users/42');
```

### Custom Headers

```dart
final res = await client.get('/admin/', headers: {
  'Authorization': 'Bearer my-jwt-token',
  'X-Request-Id': 'test-123',
});
```

### PATCH

```dart
final res = await client.patch('/users/42', body: {
  'email': 'new@example.com',
});
```

---

## TestResponse — Asserting Results

### Status Code

```dart
res.expectStatus(200);    // passes or throws TestFailure with body details
res.expectStatus(201);
res.expectStatus(404);
res.expectStatus(400);

// Raw access
expect(res.statusCode, 200);
```

### JSON Body

```dart
// Object response
final data = res.json();           // Map<String, dynamic>
expect(data['name'], 'Alice');
expect(data['id'], isNotNull);

// Array response
final list = res.jsonList();       // List<dynamic>
expect(list.length, 3);
expect(list.first['name'], 'Alice');
```

### Raw Body

```dart
final raw = res.body;              // String
expect(raw, contains('Hello'));
```

### Headers

```dart
expect(res.headers['content-type'], 'application/json');
expect(res.headers['x-request-id'], isNotNull);
```

---

## Bean Overrides — Mocking Dependencies

Replace real beans with test doubles. Overrides run AFTER `$configure`, so they replace whatever was registered.

### Override with an Instance

```dart
test('mock repository', () async {
  await bootTest($configure, overrides: (container) {
    container.override<UserRepository>(MockUserRepository());
  }, test: (client, container) async {
    final res = await client.get('/users/1');
    res.expectStatus(200);
    expect(res.json()['name'], 'Mock User');
  });
});
```

### Override with a Factory

For beans that need the container during creation:

```dart
test('mock with factory', () async {
  await bootTest($configure, overrides: (container) {
    container.overrideFactory<EmailService>(MockEmailServiceDefinition());
  }, test: (client, container) async {
    // MockEmailServiceDefinition.create(container) is called when EmailService is first accessed
  });
});
```

### Multiple Overrides

```dart
test('full isolation', () async {
  await bootTest($configure, overrides: (container) {
    container.override<UserRepository>(InMemoryUserRepo());
    container.override<EmailService>(NoOpEmailService());
    container.override<PaymentGateway>(FakePaymentGateway());
  }, test: (client, container) async {
    final res = await client.post('/orders/', body: {'item': 'book', 'qty': 1});
    res.expectStatus(201);
  });
});
```

---

## Config Overrides

Pass properties to enable/disable features or point to test resources:

```dart
test('with custom config', () async {
  await bootTest($configure, properties: {
    'pg.host': 'localhost',
    'pg.port': '5433',
    'pg.database': 'myapp_test',
    'feature.new-ui': 'true',
  }, test: (client, container) async {
    // Beans with @Requires(property: 'pg.host') will load
    // Beans with @Value('${pg.host}') get 'localhost'
  });
});
```

### Disabling Conditional Beans

```dart
test('without redis', () async {
  // Don't pass redis.host → RedisClient (@Requires(property: 'redis.host')) won't load
  await bootTest($configure, properties: {
    'pg.host': 'localhost',
  }, test: (client, container) async {
    expect(container.has<RedisClient>(), isFalse);
  });
});
```

---

## Test Environment

Default env is `test`. This means `application-test.yml` is loaded automatically:

```yaml
# application-test.yml
pg:
  host: localhost
  database: myapp_test

boot:
  logging:
    level: warn              # quieter in tests
    request-logging: false   # no request logs in test output
```

Override the environment:

```dart
await bootTest($configure, env: 'integration', test: (client, container) async {
  // Loads application-integration.yml
});
```

---

## Testing Controllers

### CRUD Operations

```dart
void main() {
  group('UserController', () {
    test('list users', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/users/');
        res.expectStatus(200);
        expect(res.jsonList(), isList);
      });
    });

    test('get user by id', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/users/1');
        res.expectStatus(200);
        expect(res.json()['id'], '1');
      });
    });

    test('get non-existent user returns 404', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/users/999');
        res.expectStatus(404);
        expect(res.json()['error'], contains('not found'));
      });
    });

    test('create user', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/users/', body: {
          'name': 'Alice',
          'email': 'alice@test.com',
        });
        res.expectStatus(201);
        expect(res.json()['name'], 'Alice');
        expect(res.json()['id'], isNotNull);
      });
    });

    test('create user with missing required field returns 400', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/users/', body: {'name': 'Alice'});
        // If email is a non-nullable @Body field, returns 400
        res.expectStatus(400);
      });
    });

    test('update user', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.put('/users/1', body: {'name': 'Updated'});
        res.expectStatus(200);
        expect(res.json()['name'], 'Updated');
      });
    });

    test('delete user', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.delete('/users/1');
        res.expectStatus(204);
      });
    });
  });
}
```

### Query Parameters

```dart
test('search with query params', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/users?name=Alice&role=admin');
    res.expectStatus(200);
    expect(res.jsonList().every((u) => u['role'] == 'admin'), isTrue);
  });
});
```

### Required vs Optional Parameters

```dart
// Controller: Future<Response> search(@QueryParam() String query, @QueryParam() String? page)

test('missing required query param returns 400', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/search');  // no ?query=
    res.expectStatus(400);
    expect(res.json()['error'], contains('query'));
  });
});

test('optional param works without value', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/search?query=dart');  // no page, that's ok
    res.expectStatus(200);
  });
});
```

---

## Testing Authentication & Security

### Unauthenticated Access

```dart
test('protected endpoint rejects without auth', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/admin/dashboard');
    res.expectStatus(401);
  });
});
```

### With Bearer Token

```dart
test('protected endpoint works with valid token', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/admin/dashboard', headers: {
      'Authorization': 'Bearer valid-admin-token',
    });
    res.expectStatus(200);
  });
});
```

### Mock Auth Provider

```dart
test('always authenticated', () async {
  await bootTest($configure, overrides: (container) {
    container.override<AuthenticationProvider>(AlwaysAuthProvider());
  }, test: (client, container) async {
    final res = await client.get('/admin/dashboard');
    res.expectStatus(200);  // passes because mock always authenticates
  });
});

class AlwaysAuthProvider implements AuthenticationProvider {
  @override
  Future<Authentication?> authenticate(AuthenticationRequest req) async {
    return Authentication(name: 'test-user', roles: ['admin']);
  }
}
```

### Role-Based Access

```dart
test('user without admin role gets 403', () async {
  await bootTest($configure, overrides: (container) {
    container.override<AuthenticationProvider>(UserRoleAuthProvider());
  }, test: (client, container) async {
    final res = await client.get('/admin/dashboard', headers: {
      'Authorization': 'Bearer user-token',
    });
    res.expectStatus(403);
  });
});
```

---

## Testing Error Handling

### Built-in Exceptions

```dart
test('NotFoundException returns 404', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/users/nonexistent');
    res.expectStatus(404);
    expect(res.json()['error'], isNotNull);
  });
});

test('unhandled exception returns 500', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/broken-endpoint');
    res.expectStatus(500);
  });
});
```

### Custom Exception Handlers

```dart
// If you have: ExceptionHandler<InsufficientFundsException>
test('custom exception handler', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.post('/payments/', body: {'amount': 99999});
    res.expectStatus(402);
    expect(res.json()['error'], contains('Insufficient funds'));
  });
});
```

---

## Testing Serialization

```dart
// Controller returns @Serializable() class directly
test('auto-serialized response', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/products/1');
    res.expectStatus(200);
    expect(res.json()['name'], isA<String>());
    expect(res.json()['price'], isA<num>());
    expect(res.headers['content-type'], contains('application/json'));
  });
});
```

---

## Testing Filters

Filters run in tests just like in production:

```dart
test('logging filter adds request-id header', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/hello/');
    expect(res.headers['x-request-id'], isNotNull);
  });
});

test('rate limit filter blocks excessive requests', () async {
  await bootTest($configure, test: (client, container) async {
    for (var i = 0; i < 100; i++) {
      await client.get('/api/data');
    }
    final res = await client.get('/api/data');
    res.expectStatus(429);
  });
});
```

---

## Testing Events

```dart
test('creating user publishes UserCreatedEvent', () async {
  await bootTest($configure, test: (client, container) async {
    final events = <dynamic>[];
    container.get<EventBus>().on<UserCreatedEvent>((e) => events.add(e));

    await client.post('/users/', body: {'name': 'Alice', 'email': 'a@b.com'});

    expect(events.length, 1);
    expect(events.first.name, 'Alice');
  });
});
```

---

## Testing Services Directly

You don't have to go through HTTP — access beans directly:

```dart
test('UserService.findById', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<UserService>();
    final user = await service.findById('1');
    expect(user, isNotNull);
    expect(user!.name, 'Alice');
  });
});

test('OrderService calculates total', () async {
  await bootTest($configure, overrides: (container) {
    container.override<ProductRepository>(FakeProductRepo());
  }, test: (client, container) async {
    final service = container.get<OrderService>();
    final total = await service.calculateTotal(['item-1', 'item-2']);
    expect(total, 29.99);
  });
});
```

---

## Testing Library Beans

Library authors test using their own generated context:

```dart
import 'package:boot_test/boot_test.dart';
import 'package:boot_redis/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('RedisClient loads when configured', () async {
    await bootTest($configure, properties: {
      'redis.host': 'localhost',
      'redis.port': '6379',
    }, test: (client, container) async {
      expect(container.has<RedisClient>(), isTrue);
    });
  });

  test('RedisClient does NOT load without config', () async {
    await bootTest($configure, test: (client, container) async {
      // No redis.host → @Requires skips it
      expect(container.has<RedisClient>(), isFalse);
    });
  });
}
```

---

## Integration Tests with Testcontainers

Use [testainers](https://pub.dev/packages/testainers) to spin up real services in Docker:

### PostgreSQL

```dart
import 'package:testainers/testainers.dart';

final pg = TestainersPostgresql();

void main() {
  setUpAll(() => pg.start());
  tearDownAll(() => pg.stop());

  test('real database', () async {
    await bootTest($configure, properties: {
      'pg.host': 'localhost',
      'pg.port': pg.port.toString(),
      'pg.database': pg.database,
      'pg.username': pg.username,
      'pg.password': pg.password,
    }, test: (client, container) async {
      final res = await client.post('/todos/', body: {'title': 'Buy milk'});
      res.expectStatus(201);

      final list = await client.get('/todos/');
      expect(list.jsonList().length, 1);
    });
  });
}
```

### Redis

```dart
final redis = TestainersRedis();

void main() {
  setUpAll(() => redis.start());
  tearDownAll(() => redis.stop());

  test('cache integration', () async {
    await bootTest($configure, properties: {
      'redis.host': 'localhost',
      'redis.port': redis.port.toString(),
    }, test: (client, container) async {
      final cache = container.get<RedisClient>();
      await cache.set('key', 'value');
      expect(await cache.get('key'), 'value');
    });
  });
}
```

### MongoDB

```dart
final mongo = TestainersMongo();

void main() {
  setUpAll(() => mongo.start());
  tearDownAll(() => mongo.stop());

  test('document store', () async {
    await bootTest($configure, properties: {
      'mongo.uri': 'mongodb://localhost:${mongo.port}/test',
    }, test: (client, container) async {
      final res = await client.post('/documents/', body: {'name': 'test'});
      res.expectStatus(201);
    });
  });
}
```

### Custom Container

```dart
final kafka = Testainer(
  image: 'confluentinc/cp-kafka:7.5.0',
  ports: {'9092': '9092'},
  env: {'KAFKA_AUTO_CREATE_TOPICS_ENABLE': 'true'},
);

void main() {
  setUpAll(() => kafka.start());
  tearDownAll(() => kafka.stop());

  test('messaging', () async {
    await bootTest($configure, properties: {
      'kafka.bootstrap-servers': 'localhost:9092',
    }, test: (client, container) async {
      // test messaging
    });
  });
}
```

---

## Test Organization

### By Feature

```
test/
├── controllers/
│   ├── user_controller_test.dart
│   ├── order_controller_test.dart
│   └── admin_controller_test.dart
├── services/
│   ├── user_service_test.dart
│   └── payment_service_test.dart
├── integration/
│   ├── database_test.dart
│   └── full_flow_test.dart
└── mocks/
    ├── mock_repos.dart
    └── mock_services.dart
```

### Shared Test Helpers

```dart
// test/helpers.dart
import 'package:boot_test/boot_test.dart';
import 'package:myapp/src/generated/boot_context.g.dart';

Future<void> appTest(
  Future<void> Function(TestClient client, BeanContainer container) test, {
  Map<String, String>? properties,
  void Function(TestContainer)? overrides,
}) async {
  await bootTest($configure,
    properties: {'pg.host': 'localhost', ...?properties},
    overrides: overrides,
    test: test,
  );
}
```

Then in tests:

```dart
import '../helpers.dart';

void main() {
  test('simple', () async {
    await appTest((client, container) async {
      final res = await client.get('/hello/');
      res.expectStatus(200);
    });
  });
}
```

---

## Running Tests

```bash
boot test                        # Build + run all tests
boot test -w                     # Watch mode: rerun on every file change
boot test -- --name "GET"        # Filter by test name substring
boot test -- -t integration      # Filter by tag
boot test -- test/controllers/   # Run specific directory
boot test -- --concurrency=1     # Sequential (for integration tests)
```

---

## Integration Tests — Real Server

`bootIntegrationTest` starts a real HTTP server on a random port. Use it for WebSocket connections, streaming, TLS, and full end-to-end flows.

```dart
import 'package:boot_test/boot_test.dart';
import 'package:myapp/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('full HTTP flow', () async {
    await bootIntegrationTest($configure, test: (client, container) async {
      final res = await client.post('/users/', body: {'name': 'Alice'});
      res.expectStatus(201);

      final list = await client.get('/users/');
      expect(list.jsonList(), hasLength(1));
    });
  });
}
```

### bootIntegrationTest() API

```dart
Future<void> bootIntegrationTest(
  BootContextRegistrar configure, {
  String env = 'test',
  Map<String, String>? properties,
  void Function(TestContainer container)? overrides,
  Duration timeout = const Duration(seconds: 15),
  required Future<void> Function(BootIntegrationClient client, TestContainer container) test,
})
```

### BootIntegrationClient

Same API as `BootTestClient` but uses real HTTP + WebSocket connections:

```dart
await client.get('/path');
await client.post('/path', body: {...});
await client.put('/path', body: {...});
await client.delete('/path');
final ws = await client.ws('/chat/room');  // real WebSocket connection
client.serverUri;  // http://127.0.0.1:<port>
```

### Bean Overrides in Integration Tests

Same as `bootTest` — swap external services while keeping the real server:

```dart
test('with mock payment gateway', () async {
  await bootIntegrationTest($configure, overrides: (container) {
    container.override<PaymentGateway>(FakePaymentGateway());
  }, test: (client, container) async {
    final res = await client.post('/checkout', body: {'amount': 100});
    res.expectStatus(200);
  });
});
```

---

## Testing WebSockets

### Unit Tests (In-Memory)

`client.ws()` creates a simulated WebSocket connection — no real server, instant execution:

```dart
test('welcome message on connect', () async {
  await bootTest($configure, properties: {
    'boot.websocket.enabled': 'true',
  }, test: (client, container) async {
    final ws = client.ws('/chat/general');
    expect(ws.received, contains('Welcome!'));
    await ws.close();
  });
});

test('echo on message', () async {
  await bootTest($configure, properties: {
    'boot.websocket.enabled': 'true',
  }, test: (client, container) async {
    final ws = client.ws('/chat/room');
    ws.send('hello');
    expect(ws.received, contains('Echo: hello'));
    await ws.close();
  });
});
```

### Integration Tests (Real WebSocket)

```dart
test('multi-client broadcast', () async {
  await bootIntegrationTest($configure, properties: {
    'boot.websocket.enabled': 'true',
  }, test: (client, container) async {
    final ws1 = await client.ws('/chat/lobby');
    await ws1.messages.first; // wait for join
    final ws2 = await client.ws('/chat/lobby');
    await ws2.messages.take(2).last; // wait for welcome

    ws1.send('hello');
    await ws2.messages.first; // wait for broadcast

    expect(ws2.received, contains('hello'));
    await ws1.close();
    await ws2.close();
  });
});
```

### BootTestWebSocket API

```dart
ws.send('message');           // send to server
ws.received;                  // List<String> — all received messages
ws.messages;                  // Stream<String> — incoming message stream
await ws.next;                // await next message
ws.isClosed;                  // connection state
await ws.close();             // close connection
```

### Authenticated WebSocket

```dart
// Unit test — pass auth directly
final ws = client.ws('/chat/room', authentication: Authentication(name: 'Alice', roles: ['user']));

// Integration test — pass token via header or query param
final ws = await client.ws('/chat/room?token=eyJ...');
```

---

## Timeouts

Both test helpers have configurable timeouts to prevent hung tests.

### Priority (highest wins)

1. `timeout:` parameter passed directly
2. `boot.test.timeout` / `boot.test.integration-timeout` from YAML config
3. Default (5s for unit, 15s for integration)

### Per-test override

```dart
await bootTest($configure, timeout: Duration(seconds: 10), test: ...);
await bootIntegrationTest($configure, timeout: Duration(seconds: 30), test: ...);
```

### Global config in application-test.yml

```yaml
# application-test.yml
boot:
  test:
    timeout: 10s              # bootTest default
    integration-timeout: 30s  # bootIntegrationTest default
```

Supported formats: `500ms`, `5s`, `2m`.

If the test exceeds the timeout, a `TimeoutException` is thrown with a clear message.

---

## Shared App for Feature Tests — BootIntegrationTestApp

For feature lifecycle tests where multiple tests share the same running server and state, use `BootIntegrationTestApp`. The server starts once per group, tests run sequentially against it.

### Basic Usage

```dart
import 'package:boot_test/boot_test.dart';
import 'package:myapp/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('User lifecycle', () {
    final app = BootIntegrationTestApp($configure);
    setUpAll(() => app.start());
    tearDownAll(() => app.stop());

    late String userId;

    test('create user', () async {
      final res = await app.client.post('/users/', body: {
        'name': 'Alice',
        'email': 'alice@test.com',
      });
      res.expectStatus(201);
      userId = res.json()['id'];
    });

    test('get user', () async {
      final res = await app.client.get('/users/$userId');
      res.expectStatus(200);
      expect(res.json()['name'], 'Alice');
    });

    test('update user', () async {
      final res = await app.client.put('/users/$userId', body: {'name': 'Bob'});
      res.expectStatus(200);
      expect(res.json()['name'], 'Bob');
    });

    test('delete user', () async {
      final res = await app.client.delete('/users/$userId');
      res.expectStatus(204);
    });

    test('deleted user returns 404', () async {
      final res = await app.client.get('/users/$userId');
      res.expectStatus(404);
    });
  });
}
```

### With WebSocket

```dart
group('Chat feature', () {
  final app = BootIntegrationTestApp($configure, properties: {
    'boot.websocket.enabled': 'true',
  });
  setUpAll(() => app.start());
  tearDownAll(() => app.stop());

  test('connect to room', () async {
    final ws = await app.client.ws('/chat/lobby');
    await ws.messages.take(2).last;
    expect(ws.received, isNotEmpty);
    await ws.close();
  });

  test('broadcast between clients', () async {
    final ws1 = await app.client.ws('/chat/lobby');
    await ws1.messages.first;
    final ws2 = await app.client.ws('/chat/lobby');
    await ws2.messages.take(2).last;

    ws1.send('hello');
    await ws2.messages.first;
    expect(ws2.received, contains('hello'));

    await ws1.close();
    await ws2.close();
  });
}
```

### With Bean Overrides

```dart
group('Payments', () {
  final app = BootIntegrationTestApp($configure, overrides: (c) {
    c.override<PaymentGateway>(FakePaymentGateway());
  });
  setUpAll(() => app.start());
  tearDownAll(() => app.stop());

  test('checkout succeeds', () async {
    final res = await app.client.post('/checkout', body: {'amount': 100});
    res.expectStatus(200);
  });
});
```

### API

```dart
class BootIntegrationTestApp {
  BootIntegrationTestApp(
    BootContextRegistrar configure, {
    void Function(TestContainer container)? overrides,
    String env = 'test',
    Map<String, String>? properties,
  });

  Future<void> start();                    // Start server. Call in setUpAll.
  Future<void> stop();                     // Stop server. Call in tearDownAll.
  BootIntegrationClient get client;        // HTTP + WebSocket client
  TestContainer get container;             // Access beans directly
  Uri get serverUri;                       // http://127.0.0.1:<port>
  bool get isRunning;                      // Server state
}
```

### When to Use What

| Scenario | Use |
|----------|-----|
| Single request/response test | `bootTest` |
| Test with real WebSocket | `bootIntegrationTest` |
| Feature lifecycle (create → update → delete) | `BootIntegrationTestApp` |
| Multiple tests sharing expensive setup | `BootIntegrationTestApp` |
| Tests that must be fully isolated | `bootTest` or `bootIntegrationTest` |

---

## Tips

- **Tests are fast** — in-memory, no network, no port binding. Hundreds of tests in seconds.
- **Full isolation** — each `bootTest()` creates a fresh container. No state leaks.
- **Filters run** — security, logging, CORS all execute in tests, same as production.
- **Use `properties:`** to control `@Requires` beans — enable/disable features per test.
- **Use `overrides:`** to replace slow/external deps (DB, HTTP clients, email).
- **Default env is `test`** — create `application-test.yml` for test-specific config.
- **Access beans directly** — `container.get<MyService>()` for unit-testing services without HTTP.
- **Trailing slashes** — `/users` and `/users/` both work, same as production.
