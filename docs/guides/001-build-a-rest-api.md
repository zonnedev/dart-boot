# Guide 001: Build a REST API

## What you'll build

A simple Todo API with these endpoints:

- `GET /todos/` — list all todos
- `GET /todos/<id>` — get one todo
- `POST /todos/` — create a todo
- `DELETE /todos/<id>` — delete a todo

## What you'll learn

- How to create a Boot application
- How to write a controller with routes
- How to handle JSON request and response bodies
- How to use path parameters and query parameters
- How to test your API

## Prerequisites

- Dart SDK 3.12+ installed ([install guide](https://dart.dev/get-dart))
- Boot CLI installed: `dart pub global activate boot_cli`

---

## Step 1: Create the project

Open your terminal and run:

```bash
boot create app todo_app
cd todo_app
dart pub get
```

This creates a project with this structure:

```
todo_app/
├── bin/main.dart              ← starts the server
├── lib/
│   ├── todo_app.dart          ← barrel file (exports your code)
│   └── src/
│       └── controllers/       ← your HTTP controllers go here
├── test/                      ← your tests go here
├── application.yml            ← configuration
├── build.yaml                 ← build runner config
└── pubspec.yaml               ← dependencies
```

---

## Step 2: Create the Todo model

A model is just a Dart class that represents your data. Create a new file:

**`lib/src/models/todo.dart`**

```dart
import 'package:boot/boot.dart';

part 'todo.g.dart';

/// Represents a single todo item.
/// @Serdeable generates toJson() and fromJson() automatically.
@Serdeable()
class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({required this.id, required this.title, this.completed = false});
}
```

**What's happening:** The `@Serdeable()` annotation tells Boot to generate `toJson()` and `fromJson()` at compile time. You never write serialization code manually — the framework handles it.

---

## Step 3: Create the Todo controller

A controller is a class that handles HTTP requests. Each method in the controller handles a specific URL and HTTP method (GET, POST, DELETE, etc.).

**`lib/src/controllers/todo_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../models/todo.dart';

part 'todo_controller.g.dart';

/// Handles all HTTP requests to /todos/
@Controller('/todos')
class TodoController {
  // In-memory storage (in a real app, this would be a database)
  final _todos = <String, Todo>{};
  var _nextId = 1;

  /// GET /todos/ — returns all todos as a JSON array
  @Get('/')
  Future<Response> list(Request request) async {
    return Response.json(_todos.values.map((t) => t.toJson()).toList());
  }

  /// GET /todos/<id> — returns one todo by its ID
  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async {
    final todo = _todos[id];
    if (todo == null) {
      // Return 404 if the todo doesn't exist
      throw NotFoundException('Todo $id not found');
    }
    return Response.json(todo.toJson());
  }

  /// POST /todos/ — creates a new todo from the JSON body
  @Post('/')
  Future<Response> create(Request request) async {
    // Read the JSON body sent by the client
    final body = await request.json();
    final title = body['title'] as String?;

    if (title == null || title.isEmpty) {
      throw BadRequestException('Title is required');
    }

    // Create the todo
    final id = '${_nextId++}';
    final todo = Todo(id: id, title: title);
    _todos[id] = todo;

    // Return 201 Created with the new todo as JSON
    return Response.created(todo.toJson());
  }

  /// DELETE /todos/<id> — deletes a todo
  @Delete('/<id>')
  Future<Response> delete(Request request, @PathParam() String id) async {
    if (!_todos.containsKey(id)) {
      throw NotFoundException('Todo $id not found');
    }
    _todos.remove(id);
    return Response.noContent(); // 204 — success, no body
  }
}
```

**What's happening:**

- `@Controller('/todos')` — tells Boot this class handles requests starting with `/todos`
- `@Get('/')` — this method handles `GET /todos/`
- `@Get('/<id>')` — the `<id>` part is a path parameter. Boot extracts it from the URL and passes it to your method via `@PathParam()`
- `@Post('/')` — handles `POST /todos/`
- `@Delete('/<id>')` — handles `DELETE /todos/<id>`
- `NotFoundException` and `BadRequestException` — Boot automatically converts these to proper HTTP error responses (404 and 400)

---

## Step 4: Export the controller

Boot needs to know about your controller. Add it to the barrel file:

**`lib/todo_app.dart`**

```dart
library todo_app;

export 'src/controllers/todo_controller.dart';
export 'src/models/todo.dart';
```

**Note:** The `part 'todo.g.dart';` line in the model tells Dart that generated code will be added to this file. You'll see `todo.g.dart` appear after running `boot build`.

---

## Step 5: Generate the code

Boot uses code generation to wire everything together at compile time. Run:

```bash
boot build
```

This creates:
- `lib/src/controllers/todo_controller.g.dart` — the route registrations
- `lib/src/generated/boot_context.g.dart` — the application wiring

You'll see output like:

```
⚡ Boot building...
Built with build_runner in 4s; wrote 4 outputs.
```

---

## Step 6: Run the server

```bash
boot serve
```

Output:

```
⚡ Building...
🚀 Starting server...
Boot started in 43ms — http://0.0.0.0:8080
```

Your API is now running!

---

## Step 7: Test it manually

Open another terminal and use `curl` (or any HTTP client like Postman):

**Create a todo:**

```bash
curl -X POST http://localhost:8080/todos/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Boot framework"}'
```

Response:

```json
{"id": "1", "title": "Learn Boot framework", "completed": false}
```

**List all todos:**

```bash
curl http://localhost:8080/todos/
```

Response:

```json
[{"id": "1", "title": "Learn Boot framework", "completed": false}]
```

**Get one todo:**

```bash
curl http://localhost:8080/todos/1
```

**Delete a todo:**

```bash
curl -X DELETE http://localhost:8080/todos/1
```

**Try getting a deleted todo (should be 404):**

```bash
curl http://localhost:8080/todos/1
```

Response:

```json
{"error": "Todo 1 not found"}
```

---

## Step 8: Write automated tests

Manual testing is fine for exploration, but you want automated tests that run every time you change code.

**`test/todo_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('TodoController', () {
    test('GET /todos/ returns empty list initially', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/');
        res.expectStatus(200);
        expect(res.jsonList(), isEmpty);
      });
    });

    test('POST /todos/ creates a todo', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {
          'title': 'Buy groceries',
        });
        res.expectStatus(201);
        expect(res.json()['title'], 'Buy groceries');
        expect(res.json()['id'], isNotNull);
        expect(res.json()['completed'], false);
      });
    });

    test('POST /todos/ without title returns 400', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
        expect(res.json()['error'], 'Title is required');
      });
    });

    test('GET /todos/<id> returns the todo', () async {
      await bootTest($configure, test: (client, container) async {
        // First create one
        final createRes = await client.post('/todos/', body: {'title': 'Test'});
        final id = createRes.json()['id'];

        // Then get it
        final res = await client.get('/todos/$id');
        res.expectStatus(200);
        expect(res.json()['title'], 'Test');
      });
    });

    test('GET /todos/<id> returns 404 for missing todo', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/999');
        res.expectStatus(404);
      });
    });

    test('DELETE /todos/<id> removes the todo', () async {
      await bootTest($configure, test: (client, container) async {
        // Create
        final createRes = await client.post('/todos/', body: {'title': 'Delete me'});
        final id = createRes.json()['id'];

        // Delete
        final deleteRes = await client.delete('/todos/$id');
        deleteRes.expectStatus(204);

        // Verify it's gone
        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(404);
      });
    });
  });
}
```

Run the tests:

```bash
boot test
```

Output:

```
⚡ Boot building...
🧪 Running tests...
00:00 +6: All tests passed!
```

---

## Step 9: Use watch mode during development

Instead of manually rebuilding after every change, use watch mode:

```bash
boot serve -w
```

Now every time you save a file, Boot automatically rebuilds and restarts the server. For tests:

```bash
boot test -w
```

---

## What you've learned

- `@Controller('/path')` defines a group of related endpoints
- `@Get`, `@Post`, `@Delete` map methods to HTTP verbs
- `@PathParam()` extracts values from the URL
- `request.json()` reads the JSON body
- `Response.json()`, `Response.created()`, `Response.noContent()` create responses
- `NotFoundException`, `BadRequestException` return proper error codes
- `bootTest()` lets you test without a real server
- `boot serve -w` and `boot test -w` give you instant feedback

## Next steps

- [Guide 002: Connect a Database](002-connect-a-database.md) — replace in-memory storage with PostgreSQL
- [Guide 003: Add Authentication](003-add-authentication.md) — protect your endpoints
