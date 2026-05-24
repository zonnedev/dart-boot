# HTTP Server

Compile-time HTTP routing built on shelf internally.

## Controllers

```dart
@Controller('/users')  // or @Controller() → auto-derives '/user' from class name
class UserController {
  final UserService _service;
  UserController(this._service);

  @Get('/')
  Future<Response> list(Request request) async { ... }

  @Get('/<id>')
  Future<Response> getById(Request req, @PathParam() String id) async { ... }

  @Post('/')
  Future<Response> create(Request request, @Body() CreateUserRequest body) async { ... }
}
```

### Path Auto-Derivation

If `@Controller()` has no path, it's derived from the class name:
- `UserController` → `/user`
- `OrderItemController` → `/order-item`

### Trailing Slash Tolerance

Both `/users` and `/users/` match the same route. No configuration needed.

## Parameter Binding

### Null Safety as Validation

Dart's type system drives validation:
- `String name` → **required**, returns 400 if missing
- `String? name` → **optional**, passes null if absent

```dart
@Get('/search')
Future<Response> search(
  Request request,
  @QueryParam() String query,       // 400 if missing
  @QueryParam() String? category,   // optional
  @Header() String authorization,   // 400 if missing
  @Header() String? xRequestId,     // optional
) async { ... }
```

### Annotations

| Annotation | Source | Example |
|---|---|---|
| `@PathParam()` | URL path segment | `@PathParam() String id` |
| `@QueryParam()` | Query string | `@QueryParam() String page` |
| `@Header()` | HTTP header | `@Header() String authorization` |
| `@CookieValue()` | Cookie | `@CookieValue() String session` |
| `@Body()` | Request body | `@Body() CreateUserRequest body` |

## Return Types

The controller generator handles return types automatically:

| Return Type | Behavior |
|---|---|
| `Response` | Returned as-is |
| `void` / `Future<void>` | 204 No Content |
| `String` | 200 text/plain |
| `@Serializable()` class | 200 application/json (calls toJson()) |
| `Stream<SseEvent>` | Server-Sent Events (text/event-stream) |
| `Stream<List<int>>` | Chunked binary response |

## Server-Sent Events (SSE)

```dart
@Get('/events')
Stream<SseEvent> events(Request request) async* {
  yield SseEvent(data: 'connected', event: 'open');
  while (true) {
    yield SseEvent(data: 'tick ${DateTime.now()}');
    await Future.delayed(Duration(seconds: 1));
  }
}
```

## File Uploads

```dart
@Post('/upload')
Future<Response> upload(Request request) async {
  final form = await request.multipart();
  final file = form.file('avatar');
  final name = form.field('name');
  return Response.json({
    'name': name,
    'filename': file?.filename,
    'size': file?.size,
  });
}
```

## Static Files

Configure in `application.yml`:

```yaml
boot:
  static:
    enabled: true
    path: /static
    directory: public/
    index: index.html
    cache:
      max-age: 3600
      etag: true
    gzip: true
```

Features:
- Correct MIME types for 30+ file extensions
- ETag + Last-Modified headers
- 304 Not Modified responses
- Pre-compressed `.gz` file serving
- Path traversal protection

## Streaming Responses

```dart
// Manual streaming
@Get('/download')
Future<Response> download(Request request) async {
  final stream = File('large.bin').openRead();
  return Response.stream(stream, headers: {'content-type': 'application/octet-stream'});
}
```

## Error Handling

Exceptions in controllers are caught and logged automatically:

- `HttpException` subclasses → mapped to status codes
- Custom `ExceptionHandler<E>` beans → handle specific exception types
- Unhandled exceptions → 500 + logged with filtered stack trace

The server **never crashes** from a request error. A recovery middleware catches anything that escapes the router.

## Stack Trace Filtering

Configure in `application.yml`:

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

Set `enabled: false` to see full unfiltered traces.

## CORS

```yaml
boot:
  http:
    cors:
      enabled: true
      allowed-origins:
        - http://localhost:3000
      allowed-methods:
        - GET
        - POST
      max-age: 3600
```

Preflight `OPTIONS` requests are handled automatically.
