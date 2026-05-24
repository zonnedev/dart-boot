# Guide 004: Add Error Handling

## What you'll build

Add custom error handling to the Todo app — domain-specific exceptions with proper HTTP responses, and a consistent error format across the entire API.

## What you'll learn

- How Boot handles exceptions automatically
- How to create custom domain exceptions
- How to write an `ExceptionHandler` bean
- How the error response format works
- How to test error scenarios

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: Understand built-in error handling

Boot already handles common errors. When you throw these exceptions in a controller, Boot returns the correct HTTP status:

| Exception | HTTP Status | When to use |
|---|---|---|
| `BadRequestException('msg')` | 400 | Invalid input from the client |
| `UnauthorizedException('msg')` | 401 | No valid credentials |
| `ForbiddenException('msg')` | 403 | Authenticated but not allowed |
| `NotFoundException('msg')` | 404 | Resource doesn't exist |
| `ConflictException('msg')` | 409 | Duplicate or conflicting state |
| `InternalServerException('msg')` | 500 | Something broke on the server |

You've already used some of these in Guide 001:

```dart
@Get('/<id>')
Future<Response> getById(Request request, @PathParam() String id) async {
  final todo = await _repo.findById(id);
  if (todo == null) throw NotFoundException('Todo $id not found');
  return Response.json(todo.toJson());
}
```

The response is always:

```json
{"error": "Todo 42 not found"}
```

With HTTP status 404.

---

## Step 2: Create a domain exception

Real apps have domain-specific errors. Let's say a user can only have 10 todos:

**`lib/src/exceptions/todo_limit_exception.dart`**

```dart
/// Thrown when a user tries to create more todos than allowed.
class TodoLimitException implements Exception {
  final int currentCount;
  final int maxAllowed;

  TodoLimitException({required this.currentCount, required this.maxAllowed});

  @override
  String toString() => 'Todo limit reached: $currentCount/$maxAllowed';
}
```

**What's happening:** This is a plain Dart exception. It carries context about what went wrong — how many todos exist and what the limit is.

---

## Step 3: Throw it from the controller

**`lib/src/controllers/todo_controller.dart`** — add a check in the `create` method:

```dart
@Post('/')
Future<Response> create(Request request) async {
  final body = await request.json();
  final title = body['title'] as String?;
  if (title == null || title.isEmpty) throw BadRequestException('Title is required');

  // Check the limit
  final todos = await _repo.findAll();
  if (todos.length >= 10) {
    throw TodoLimitException(currentCount: todos.length, maxAllowed: 10);
  }

  final todo = await _repo.create(title);
  return Response.created(todo.toJson());
}
```

If you try this now without a handler, Boot returns a generic 500:

```json
{"error": "Internal Server Error"}
```

That's not helpful for the client. Let's fix it.

---

## Step 4: Create a custom ExceptionHandler

An `ExceptionHandler` tells Boot how to convert your exception into an HTTP response.

**`lib/src/exceptions/todo_limit_handler.dart`**

```dart
import 'package:boot/boot.dart';
import 'todo_limit_exception.dart';

part 'todo_limit_handler.g.dart';

/// Handles TodoLimitException — returns 429 Too Many Requests.
/// Boot discovers this automatically because it implements ExceptionHandler.
@Singleton()
class TodoLimitHandler implements ExceptionHandler<TodoLimitException> {
  @override
  Response handle(Request request, TodoLimitException e) {
    return Response(429,
      headers: {'content-type': 'application/json'},
      body: '{"error": "Todo limit reached", "current": ${e.currentCount}, "max": ${e.maxAllowed}}',
    );
  }
}
```

**What's happening:**

- `implements ExceptionHandler<TodoLimitException>` — tells Boot "when a `TodoLimitException` is thrown, call me"
- Boot auto-discovers this bean — you don't register it anywhere
- You control the HTTP status code (429), headers, and body format
- The `Request` is available if you need info about what was requested

---

## Step 5: Export and build

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/exceptions/todo_limit_exception.dart';
export 'src/exceptions/todo_limit_handler.dart';
```

```bash
boot build
boot serve
```

---

## Step 6: Test it

**Manual test:**

```bash
# Create 10 todos
for i in $(seq 1 10); do
  curl -s -X POST http://localhost:8080/todos/ \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"Todo $i\"}"
done

# Try creating an 11th
curl -s -X POST http://localhost:8080/todos/ \
  -H "Content-Type: application/json" \
  -d '{"title": "One too many"}'
```

Response:

```json
{"error": "Todo limit reached", "current": 10, "max": 10}
```

Status: 429

**Automated test:**

**`test/error_handling_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Error handling', () {
    test('todo limit returns 429 with details', () async {
      await bootTest($configure, test: (client, container) async {
        // Create 10 todos
        for (var i = 0; i < 10; i++) {
          final res = await client.post('/todos/', body: {'title': 'Todo $i'});
          res.expectStatus(201);
        }

        // 11th should fail
        final res = await client.post('/todos/', body: {'title': 'Too many'});
        res.expectStatus(429);
        expect(res.json()['error'], 'Todo limit reached');
        expect(res.json()['current'], 10);
        expect(res.json()['max'], 10);
      });
    });

    test('missing title returns 400', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
        expect(res.json()['error'], 'Title is required');
      });
    });

    test('not found returns 404', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/999');
        res.expectStatus(404);
        expect(res.json()['error'], contains('not found'));
      });
    });

    test('unhandled exception returns 500', () async {
      // If something unexpected happens, Boot catches it and returns 500
      // The server never crashes
      await bootTest($configure, test: (client, container) async {
        // This tests that the server is resilient
        final res = await client.get('/todos/not-a-number');
        // Depending on your code, this might be 400 or 500
        expect(res.statusCode, greaterThanOrEqualTo(400));
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 7: Multiple exception handlers

You can have as many handlers as you need. Each handles one exception type:

```dart
@Singleton()
class DuplicateTodoHandler implements ExceptionHandler<DuplicateTodoException> {
  @override
  Response handle(Request request, DuplicateTodoException e) {
    return Response(409,
      headers: {'content-type': 'application/json'},
      body: '{"error": "A todo with this title already exists", "title": "${e.title}"}',
    );
  }
}

@Singleton()
class DatabaseTimeoutHandler implements ExceptionHandler<TimeoutException> {
  @override
  Response handle(Request request, TimeoutException e) {
    return Response(503,
      headers: {'content-type': 'application/json'},
      body: '{"error": "Service temporarily unavailable, please retry"}',
    );
  }
}
```

---

## Step 8: Error handling priority

When an exception is thrown, Boot checks in this order:

1. **Custom ExceptionHandler** — if you registered one for this exception type, it's used
2. **Built-in HttpException** — `NotFoundException`, `BadRequestException`, etc. map to status codes
3. **Fallback** — anything else becomes 500 Internal Server Error

The server **never crashes**. Even if your handler itself throws an exception, Boot catches it and returns 500.

---

## What you've learned

- Boot has built-in exceptions for common HTTP errors (400, 401, 403, 404, 409, 500)
- Create domain exceptions as plain Dart classes
- `ExceptionHandler<YourException>` converts exceptions to HTTP responses
- Boot auto-discovers handlers — just annotate with `@Singleton()`
- You control the status code, headers, and body format
- Multiple handlers can coexist — one per exception type
- The server never crashes from unhandled exceptions

## Next steps

- [Guide 005: Use Dependency Injection](005-use-dependency-injection.md) — @Named, @Primary, interfaces, and more
