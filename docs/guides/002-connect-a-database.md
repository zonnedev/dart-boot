# Guide 002: Connect a Database

## What you'll build

Extend the Todo app from Guide 001 to store todos in PostgreSQL instead of memory.

## What you'll learn

- How to inject configuration values with `@Value`
- How to use `@PostConstruct` for initialization
- How to create a repository pattern with Boot DI
- How to use `@Requires` for conditional beans
- How to test with a real database using Testcontainers

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)
- Docker installed (for PostgreSQL)

---

## Step 1: Start PostgreSQL

Create a `docker-compose.yml` in your project root:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: todo_app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
```

Start it:

```bash
docker compose up -d
```

---

## Step 2: Add the PostgreSQL dependency

**`pubspec.yaml`** — add `postgres` under dependencies:

```yaml
dependencies:
  boot: ^0.1.0
  postgres: ^3.5.0

dev_dependencies:
  boot_generator: ^0.1.0
  boot_test: ^0.1.0
  build_runner: ^2.4.0
  test: ^1.25.0
  testainers: ^0.3.0
```

Then run:

```bash
dart pub get
```

---

## Step 3: Configure the database connection

**`application.yml`** — add database config:

```yaml
boot:
  env: dev

# Database configuration
pg:
  host: localhost
  port: 5432
  database: todo_app
  username: postgres
  password: postgres
```

**What's happening:** These are just key-value pairs. Boot doesn't know they're for PostgreSQL — your code reads them via `@Value`.

---

## Step 4: Create the Database bean

This bean manages the PostgreSQL connection pool. It reads config values and initializes the pool on startup.

**`lib/src/db/database.dart`**

```dart
import 'package:boot/boot.dart';
import 'package:postgres/postgres.dart';

part 'database.g.dart';

/// Manages the PostgreSQL connection pool.
/// Only loads if pg.host is configured (won't crash in tests without a DB).
@Singleton()
@Requires(property: 'pg.host')
class Database {
  final String _host;
  final int _port;
  final String _database;
  final String _username;
  final String _password;
  late final Pool _pool;

  Database(
    @Value('\${pg.host}') this._host,
    @Value('\${pg.port:5432}') this._port,
    @Value('\${pg.database:postgres}') this._database,
    @Value('\${pg.username:postgres}') this._username,
    @Value('\${pg.password:postgres}') this._password,
  );

  /// Called automatically after the bean is created.
  /// Initializes the connection pool.
  @PostConstruct()
  void init() {
    _pool = Pool.withEndpoints(
      [Endpoint(host: _host, port: _port, database: _database, username: _username, password: _password)],
      settings: PoolSettings(maxConnectionCount: 10, sslMode: SslMode.disable),
    );
  }

  /// Execute a SQL query with named parameters.
  Future<Result> query(String sql, {Map<String, dynamic>? params}) =>
      _pool.execute(Sql.named(sql), parameters: params ?? {});

  /// Execute a query and return results as a list of maps.
  Future<List<Map<String, dynamic>>> queryRows(String sql, {Map<String, dynamic>? params}) async {
    final result = await query(sql, params: params);
    return result.map((row) => row.toColumnMap()).toList();
  }

  /// Called automatically when the app shuts down.
  @PreDestroy()
  void close() => _pool.close();
}
```

**What's happening:**

- `@Value('\${pg.host}')` — reads the value of `pg.host` from `application.yml`. The `\${}` syntax is a placeholder that Boot resolves at startup.
- `@Value('\${pg.port:5432}')` — the `:5432` part is a default value. If `pg.port` isn't set, it uses `5432`.
- `@Requires(property: 'pg.host')` — this bean only loads if `pg.host` is configured. Without this, the app would crash in environments where no database is available (like some test scenarios).
- `@PostConstruct()` — runs after the constructor. Use it for initialization that can't happen in the constructor (like creating the pool).
- `@PreDestroy()` — runs when the app shuts down. Use it to clean up resources.

---

## Step 5: Create the TodoRepository

The repository handles all database operations for todos. It depends on the `Database` bean.

**`lib/src/repositories/todo_repository.dart`**

```dart
import 'package:boot/boot.dart';
import '../db/database.dart';
import '../models/todo.dart';

part 'todo_repository.g.dart';

/// Handles all database operations for todos.
@Singleton()
@Requires(property: 'pg.host')
class TodoRepository {
  final Database _db;

  /// Boot automatically injects the Database bean here.
  TodoRepository(this._db);

  /// Called automatically on startup — creates the table if it doesn't exist.
  @PostConstruct()
  Future<void> init() async {
    await _db.query('''
      CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        completed BOOLEAN NOT NULL DEFAULT false
      )
    ''');
  }

  /// Get all todos.
  Future<List<Todo>> findAll() async {
    final rows = await _db.queryRows('SELECT id, title, completed FROM todos ORDER BY id');
    return rows.map((r) => Todo(
      id: r['id'].toString(),
      title: r['title'] as String,
      completed: r['completed'] as bool,
    )).toList();
  }

  /// Get one todo by ID.
  Future<Todo?> findById(String id) async {
    final rows = await _db.queryRows(
      'SELECT id, title, completed FROM todos WHERE id = @id',
      params: {'id': int.parse(id)},
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Todo(id: r['id'].toString(), title: r['title'] as String, completed: r['completed'] as bool);
  }

  /// Create a new todo. Returns the created todo with its generated ID.
  Future<Todo> create(String title) async {
    final rows = await _db.queryRows(
      'INSERT INTO todos (title) VALUES (@title) RETURNING id, title, completed',
      params: {'title': title},
    );
    final r = rows.first;
    return Todo(id: r['id'].toString(), title: r['title'] as String, completed: r['completed'] as bool);
  }

  /// Delete a todo by ID. Returns true if it existed.
  Future<bool> delete(String id) async {
    final result = await _db.query(
      'DELETE FROM todos WHERE id = @id',
      params: {'id': int.parse(id)},
    );
    return result.affectedRows > 0;
  }
}
```

**What's happening:**

- `TodoRepository(this._db)` — Boot sees that the constructor needs a `Database` and injects it automatically. You never write `new Database(...)` yourself.
- `@Requires(property: 'pg.host')` — same as Database. If there's no DB config, this bean doesn't load.
- `@PostConstruct()` on `init()` — runs automatically after the bean is created. Here it creates the `todos` table if it doesn't exist. This means the app is self-migrating — just start it and the schema is ready.
- The repository uses named parameters (`@id`, `@title`) in SQL to prevent SQL injection.

---

## Step 6: Update the controller

Replace the in-memory storage with the repository:

**`lib/src/controllers/todo_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

part 'todo_controller.g.dart';

/// Handles all HTTP requests to /todos/
@Controller('/todos')
class TodoController {
  final TodoRepository _repo;

  /// Boot injects TodoRepository automatically.
  TodoController(this._repo);

  @Get('/')
  Future<Response> list(Request request) async {
    final todos = await _repo.findAll();
    return Response.json(todos.map((t) => t.toJson()).toList());
  }

  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async {
    final todo = await _repo.findById(id);
    if (todo == null) throw NotFoundException('Todo $id not found');
    return Response.json(todo.toJson());
  }

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final title = body['title'] as String?;
    if (title == null || title.isEmpty) throw BadRequestException('Title is required');

    final todo = await _repo.create(title);
    return Response.created(todo.toJson());
  }

  @Delete('/<id>')
  Future<Response> delete(Request request, @PathParam() String id) async {
    final deleted = await _repo.delete(id);
    if (!deleted) throw NotFoundException('Todo $id not found');
    return Response.noContent();
  }
}
```

**What's happening:** The controller no longer manages data itself. It delegates to `TodoRepository`, which delegates to `Database`. Boot wires the chain automatically:

```
TodoController → TodoRepository → Database → PostgreSQL
```

---

## Step 7: Update exports

**`lib/todo_app.dart`**

```dart
library todo_app;

export 'src/controllers/todo_controller.dart';
export 'src/db/database.dart';
export 'src/models/todo.dart';
export 'src/repositories/todo_repository.dart';
```

---

## Step 8: Build and run

```bash
boot build
boot serve
```

The table is created automatically on startup thanks to `@PostConstruct` on the repository.

---

## Step 9: Test it

```bash
# Create
curl -X POST http://localhost:8080/todos/ -H "Content-Type: application/json" -d '{"title": "Buy milk"}'
# {"id":"1","title":"Buy milk","completed":false}

# List
curl http://localhost:8080/todos/
# [{"id":"1","title":"Buy milk","completed":false}]

# Get one
curl http://localhost:8080/todos/1
# {"id":"1","title":"Buy milk","completed":false}

# Delete
curl -X DELETE http://localhost:8080/todos/1
# (204 No Content)
```

---

## Step 10: Write automated tests with Testcontainers

For tests, we spin up a real PostgreSQL in Docker automatically:

**`test/todo_db_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/repositories/todo_repository.dart';
import 'package:test/test.dart';
import 'package:testainers/testainers.dart';

// This starts a real PostgreSQL container for testing
final pg = TestainersPostgresql();

void main() {
  // Start PostgreSQL before all tests
  setUpAll(() async {
    await pg.start();
  });

  // Stop it after all tests
  tearDownAll(() async {
    await pg.stop();
  });

  group('TodoController with real DB', () {
    test('full CRUD flow', () async {
      await bootTest($configure, properties: {
        'pg.host': 'localhost',
        'pg.port': pg.port.toString(),
        'pg.database': pg.database,
        'pg.username': pg.username,
        'pg.password': pg.password,
      }, test: (client, container) async {
        // Table is created automatically by @PostConstruct

        // Create a todo
        final createRes = await client.post('/todos/', body: {'title': 'Test todo'});
        createRes.expectStatus(201);
        expect(createRes.json()['title'], 'Test todo');
        final id = createRes.json()['id'];

        // List todos
        final listRes = await client.get('/todos/');
        listRes.expectStatus(200);
        expect(listRes.jsonList().length, 1);

        // Get by ID
        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(200);
        expect(getRes.json()['title'], 'Test todo');

        // Delete
        final deleteRes = await client.delete('/todos/$id');
        deleteRes.expectStatus(204);

        // Verify deleted
        final afterDelete = await client.get('/todos/$id');
        afterDelete.expectStatus(404);
      });
    });
  });
}
```

**What's happening:**

- `TestainersPostgresql()` — starts a real PostgreSQL Docker container
- `properties: {...}` — overrides the config to point to the test container
- The test runs against a real database, then the container is destroyed
- Each test gets a fresh database — no leftover data

Run:

```bash
boot test
```

---

## Step 11: Test without a database

Sometimes you want fast unit tests that don't need Docker. Use bean overrides:

**`test/todo_unit_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/models/todo.dart';
import 'package:todo_app/src/repositories/todo_repository.dart';
import 'package:test/test.dart';

/// A fake repository that stores todos in memory (no database needed).
class FakeTodoRepository implements TodoRepository {
  final _todos = <String, Todo>{};
  var _nextId = 1;

  @override
  Future<void> createTable() async {}

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

void main() {
  group('TodoController (unit test, no DB)', () {
    test('creates and lists todos', () async {
      await bootTest($configure, properties: {
        'pg.host': 'fake', // needed so @Requires passes
      }, overrides: (container) {
        container.override<TodoRepository>(FakeTodoRepository());
      }, test: (client, container) async {
        // Create
        final res = await client.post('/todos/', body: {'title': 'Unit test'});
        res.expectStatus(201);

        // List
        final list = await client.get('/todos/');
        list.expectStatus(200);
        expect(list.jsonList().length, 1);
      });
    });
  });
}
```

**What's happening:**

- `FakeTodoRepository` — a simple in-memory implementation, no database
- `overrides: (container) { container.override<TodoRepository>(...) }` — replaces the real repo with the fake
- Tests run instantly — no Docker, no network

---

## What you've learned

- `@Value('\${key:default}')` reads config from `application.yml`
- `@PostConstruct()` runs initialization after the bean is created
- `@PreDestroy()` cleans up when the app shuts down
- `@Requires(property: 'key')` makes a bean conditional — it only loads if the config exists
- Constructor injection wires beans together automatically
- Testcontainers give you real database tests
- Bean overrides give you fast unit tests without external dependencies

## Next steps

- [Guide 003: Add Authentication](003-add-authentication.md) — protect your endpoints with JWT
