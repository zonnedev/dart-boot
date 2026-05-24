# Error Handling

Boot provides a layered error handling system: built-in HTTP exceptions, custom exception handlers, and crash-proof server protection.

## Built-in HTTP Exceptions

Throw these from controllers for automatic status code mapping:

```dart
@Controller('/users')
class UserController {
  final UserRepository _repo;
  UserController(this._repo);

  @Get('/<id>')
  Future<Response> getById(Request req, @PathParam() String id) async {
    final user = await _repo.findById(id);
    if (user == null) throw NotFoundException('User $id not found');
    return Response.json(user.toJson());
  }

  @Post('/')
  Future<Response> create(Request req, @Body() CreateUserRequest body) async {
    if (body.email.isEmpty) throw BadRequestException('Email is required');
    final user = await _repo.save(body);
    return Response.created(user.toJson());
  }
}
```

**Test:**
```dart
test('throws 404 for missing user', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/users/nonexistent');
    res.expectStatus(404);
    expect(res.json()['error'], 'User nonexistent not found');
  });
});

test('throws 400 for invalid input', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.post('/users/', body: {'email': ''});
    res.expectStatus(400);
    expect(res.json()['error'], 'Email is required');
  });
});
```

### Available Exceptions

| Exception | Status Code |
|---|---|
| `BadRequestException` | 400 |
| `UnauthorizedException` | 401 |
| `ForbiddenException` | 403 |
| `NotFoundException` | 404 |
| `ConflictException` | 409 |
| `InternalServerException` | 500 |
| `HttpException(statusCode, message)` | Any |

## Custom Exception Handlers

Handle domain-specific exceptions with a typed handler:

```dart
// Your domain exception
class InsufficientFundsException implements Exception {
  final double balance;
  final double required;
  InsufficientFundsException(this.balance, this.required);
}

// Handler bean — auto-discovered
@Singleton()
class InsufficientFundsHandler implements ExceptionHandler<InsufficientFundsException> {
  @override
  Response handle(Request request, InsufficientFundsException e) {
    return Response(402,
      headers: {'content-type': 'application/json'},
      body: '{"error":"Insufficient funds","balance":${e.balance},"required":${e.required}}',
    );
  }
}
```

```dart
// Controller that throws it
@Post('/transfer')
Future<Response> transfer(Request req, @Body() TransferRequest body) async {
  final balance = await _account.getBalance();
  if (balance < body.amount) {
    throw InsufficientFundsException(balance, body.amount);
  }
  // ...
}
```

**Test:**
```dart
test('custom exception handler returns 402', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.post('/transfer', body: {'amount': 99999});
    res.expectStatus(402);
    expect(res.json()['error'], 'Insufficient funds');
    expect(res.json()['balance'], isA<num>());
  });
});
```

## Error Response Format

All errors return consistent JSON:

```json
{"error": "Human-readable error message"}
```

For custom handlers, you control the format entirely.

## Unhandled Exceptions

If an exception has no matching handler and isn't an `HttpException`, Boot:
1. Logs it with a filtered stack trace
2. Returns `500 {"error": "Internal Server Error"}`
3. **Does not crash** — the server continues serving other requests

```dart
@Get('/broken')
Future<Response> broken(Request req) async {
  throw StateError('Something went very wrong');
}
```

**Test:**
```dart
test('unhandled exception returns 500', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/broken');
    res.expectStatus(500);
    expect(res.json()['error'], 'Internal Server Error');
  });
});
```

## Server Crash Protection

Boot has two layers of protection:

1. **Router catch block** — catches exceptions in controllers and filters, maps to responses
2. **Recovery middleware** — catches anything that escapes the router (malformed requests, parsing errors)

A malicious client sending garbage data will never crash your server. The error is logged and a 500 is returned.

## Stack Trace Filtering

Exception stack traces are filtered to remove framework internals. Configure in `application.yml`:

```yaml
boot:
  logging:
    stacktrace:
      filter:
        enabled: true
        max-depth: 10
        exclude:
          - dart:
          - package:shelf/
          - package:shelf_router/
```

Output:
```
[ERROR] BootRouter: GET /broken ERROR: Bad state: Something went very wrong
#0      UserController.broken (package:myapp/src/controllers/user_controller.dart:42:5)
#1      $UserControllerRoutes (package:myapp/src/controllers/user_controller.g.dart:55:41)
#2      BootRouter._wrapHandler (package:boot_http/src/http/router.dart:162:70)
```

Set `enabled: false` to see full unfiltered traces for debugging.

## Null Safety as Validation

Dart's type system drives parameter validation automatically:

```dart
@Get('/search')
Future<Response> search(
  Request req,
  @QueryParam() String query,      // REQUIRED — 400 if missing
  @QueryParam() int limit,         // REQUIRED — 400 if missing
  @QueryParam() String? category,  // OPTIONAL — null if missing
) async { ... }
```

**Test:**
```dart
test('missing required param returns 400', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/search');  // no ?query=
    res.expectStatus(400);
    expect(res.json()['error'], contains('query'));
  });
});

test('optional param can be omitted', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/search?query=dart&limit=10');
    res.expectStatus(200);  // category is null, that's fine
  });
});
```
