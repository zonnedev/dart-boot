# Guide 020: Test Your Application

## What you'll build

A comprehensive test suite covering unit tests, integration tests, and end-to-end tests — with mocking, testcontainers, and CI pipeline setup.

## What you'll learn

- How to structure tests for a Boot app
- Unit tests (services in isolation)
- Integration tests (with real database)
- End-to-end tests (full HTTP flow)
- Mocking strategies
- CI pipeline configuration

## Prerequisites

- Completed previous guides (especially [Guide 001](001-build-a-rest-api.md) and [Guide 002](002-connect-a-database.md))

---

## Step 1: Test structure

```
test/
├── unit/                    ← fast, no external deps
│   ├── services/
│   │   └── todo_service_test.dart
│   └── models/
│       └── todo_test.dart
├── integration/             ← with real database
│   └── todo_repository_test.dart
├── e2e/                     ← full HTTP flow
│   ├── todo_api_test.dart
│   └── auth_flow_test.dart
└── mocks/                   ← shared test doubles
    ├── mock_repos.dart
    └── mock_services.dart
```

---

## Step 2: Unit tests — services in isolation

Test business logic without HTTP, database, or any external dependency:

**`test/unit/services/todo_service_test.dart`**

```dart
import 'package:test/test.dart';
import 'package:todo_app/src/models/todo.dart';

// Test the model directly — no Boot, no container
void main() {
  group('Todo model', () {
    test('creates with defaults', () {
      final todo = Todo(id: '1', title: 'Test');
      expect(todo.completed, isFalse);
    });

    test('toJson includes all fields', () {
      final todo = Todo(id: '1', title: 'Test', completed: true);
      final json = todo.toJson();
      expect(json['id'], '1');
      expect(json['title'], 'Test');
      expect(json['completed'], true);
    });
  });
}
```

Run just unit tests:
```bash
dart test test/unit/
```

---

## Step 3: Integration tests — with bootTest

Test beans wired together, using the real container but mocked externals:

**`test/integration/todo_api_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Todo API', () {
    test('full CRUD lifecycle', () async {
      await bootTest($configure, test: (client, container) async {
        // Create
        final createRes = await client.post('/todos/', body: {'title': 'Integration test'});
        createRes.expectStatus(201);
        final id = createRes.json()['id'];
        expect(id, isNotNull);

        // Read
        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(200);
        expect(getRes.json()['title'], 'Integration test');

        // List
        final listRes = await client.get('/todos/');
        listRes.expectStatus(200);
        expect(listRes.jsonList(), isNotEmpty);

        // Delete
        final deleteRes = await client.delete('/todos/$id');
        deleteRes.expectStatus(204);

        // Verify deleted
        final afterRes = await client.get('/todos/$id');
        afterRes.expectStatus(404);
      });
    });

    test('validation errors', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
        expect(res.json()['error'], contains('required'));
      });
    });

    test('not found errors', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/nonexistent');
        res.expectStatus(404);
      });
    });
  });
}
```

---

## Step 4: Mocking dependencies

Create reusable mocks:

**`test/mocks/mock_repos.dart`**

```dart
import 'package:todo_app/src/models/todo.dart';
import 'package:todo_app/src/repositories/todo_repository.dart';

class InMemoryTodoRepo implements TodoRepository {
  final _todos = <String, Todo>{};
  var _nextId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<List<Todo>> findAll() async => _todos.values.toList();

  @override
  Future<Todo?> findById(String id) async => _todos[id];

  @override
  Future<Todo> create(String title) async {
    final id = '${_nextId++}';
    final todo = Todo(id: id, title: title);
    _todos[id] = todo;
    return todo;
  }

  @override
  Future<bool> delete(String id) async => _todos.remove(id) != null;
}
```

Use in tests:

```dart
test('with mocked repo', () async {
  await bootTest($configure, overrides: (container) {
    container.override<TodoRepository>(InMemoryTodoRepo());
  }, test: (client, container) async {
    final res = await client.post('/todos/', body: {'title': 'Mocked'});
    res.expectStatus(201);
  });
});
```

---

## Step 5: Database integration tests with Testcontainers

**`test/integration/todo_db_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';
import 'package:testainers/testainers.dart';

final pg = TestainersPostgresql();

void main() {
  setUpAll(() => pg.start());
  tearDownAll(() => pg.stop());

  group('Todo with real PostgreSQL', () {
    test('persists across requests', () async {
      await bootTest($configure, properties: {
        'pg.host': 'localhost',
        'pg.port': pg.port.toString(),
        'pg.database': pg.database,
        'pg.username': pg.username,
        'pg.password': pg.password,
      }, test: (client, container) async {
        // Create
        final res = await client.post('/todos/', body: {'title': 'DB test'});
        res.expectStatus(201);
        final id = res.json()['id'];

        // Verify it's in the database
        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(200);
        expect(getRes.json()['title'], 'DB test');
      });
    });
  });
}
```

---

## Step 6: Testing authentication

**`test/e2e/auth_flow_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/jwt_service.dart';
import 'package:test/test.dart';

void main() {
  group('Auth flow', () {
    test('login → use token → access protected resource', () async {
      await bootTest($configure, test: (client, container) async {
        // Login
        final loginRes = await client.post('/auth/login', body: {
          'username': 'admin',
          'password': 'admin123',
        });
        loginRes.expectStatus(200);
        final token = loginRes.json()['token'];

        // Use token
        final res = await client.get('/todos/', headers: {
          'Authorization': 'Bearer $token',
        });
        res.expectStatus(200);
      });
    });

    test('expired token is rejected', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/', headers: {
          'Authorization': 'Bearer expired.invalid.token',
        });
        res.expectStatus(401);
      });
    });
  });
}
```

---

## Step 7: Testing events

```dart
test('creating todo publishes event', () async {
  await bootTest($configure, test: (client, container) async {
    final events = <dynamic>[];
    container.get<EventBus>().subscribe<TodoCreatedEvent>((e) => events.add(e));

    await client.post('/todos/', body: {'title': 'Event test'});

    await Future.delayed(Duration(milliseconds: 50));
    expect(events.length, 1);
  });
});
```

---

## Step 8: Testing scheduled jobs

```dart
test('cleanup job runs without error', () async {
  await bootTest($configure, test: (client, container) async {
    final job = container.get<CleanupJob>();
    // Call directly — scheduler doesn't auto-run in tests
    await job.cleanExpiredSessions();
  });
});
```

---

## Step 9: Test helper for repeated setup

**`test/helpers.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';

/// Shorthand for bootTest with common config.
Future<void> appTest(
  Future<void> Function(TestClient client, BeanContainer container) test, {
  Map<String, String>? properties,
  void Function(TestContainer)? overrides,
}) async {
  await bootTest($configure,
    properties: {
      'pg.host': 'localhost',
      ...?properties,
    },
    overrides: overrides,
    test: test,
  );
}
```

Use it:
```dart
test('simple', () async {
  await appTest((client, container) async {
    final res = await client.get('/todos/');
    res.expectStatus(200);
  });
});
```

---

## Step 10: CI pipeline (GitHub Actions)

**`.github/workflows/test.yml`**

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: todo_app_test
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: '3.12.0'

      - run: dart pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: dart test
        env:
          PG_HOST: localhost
          PG_PORT: 5432
          PG_DATABASE: todo_app_test
          PG_USERNAME: postgres
          PG_PASSWORD: postgres
```

---

## Step 11: Running tests

```bash
# All tests
boot test

# Watch mode — rerun on changes
boot test -w

# Only unit tests (fast)
dart test test/unit/

# Only integration tests
dart test test/integration/

# Specific file
dart test test/e2e/auth_flow_test.dart

# With name filter
boot test -- --name "CRUD"

# Verbose output
boot test -- --reporter expanded
```

---

## Tips

| Tip | Why |
|---|---|
| Keep unit tests fast (no `bootTest`) | Run hundreds in <1 second |
| Use `bootTest` for integration | Tests the real wiring |
| Mock external services | Don't call real APIs in CI |
| Use Testcontainers for DB tests | Real database, disposable |
| Test error paths too | 400, 401, 403, 404, 500 |
| Each `bootTest` is isolated | No state leaks between tests |
| Use `properties:` to control `@Requires` | Enable/disable features per test |

---

## What you've learned

- Structure tests by type: unit / integration / e2e
- Unit tests: no Boot, no container, just Dart
- Integration tests: `bootTest` with mocks or real services
- Testcontainers: real database in Docker, auto-cleanup
- Mock with `overrides:` — replace any bean
- Test auth flows end-to-end
- Test events by subscribing to `EventBus`
- Test jobs by calling methods directly
- CI pipeline with GitHub Actions + PostgreSQL service

---

That's the complete guide series! You now know how to build, test, secure, and deploy a Boot application from scratch.
