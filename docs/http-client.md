# HTTP Client

Boot provides both a declarative `@Client` interface and a programmatic `HttpClient` for making HTTP calls. Both support filters, timeouts, and automatic error handling.

## Declarative Client

Define an interface with route annotations — Boot generates the implementation at compile time.

### Inline URL

```dart
@Client(url: 'https://api.example.com', path: '/v1')
abstract class UserClient {
  @Get('/users/<id>')
  Future<User> getById(@PathParam() String id);

  @Post('/users')
  Future<User> create(@Body() CreateUserRequest body);

  @Get('/users')
  Future<List<dynamic>> list(@QueryParam() int page);
}
```

### Named Service (YAML config)

```dart
@Client(name: 'user-service')
abstract class UserClient {
  @Get('/users/<id>')
  Future<User> getById(@PathParam() String id);
}
```

```yaml
boot:
  http:
    client:
      services:
        user-service:
          url: https://api.users.com
          connect-timeout: 10s
          read-timeout: 60s
```

Using `name` is mutually exclusive with `url` — specifying both is a compile-time error.

## Parameter Annotations

| Annotation | Description |
|-----------|-------------|
| `@PathParam()` | Substitutes into URL path (`/users/<id>`) |
| `@QueryParam()` | Appended as query string (`?page=1`) |
| `@Header()` | Sent as HTTP header |
| `@CookieValue()` | Sent as cookie header |
| `@Body()` | Serialized as JSON request body |

`@Body` parameters must be annotated with `@Serdeable` or `@Serializable`. Return types must have `@Serdeable` or `@Deserializable`. This is validated at compile time.

## Programmatic HttpClient

Inject `HttpClient` directly for ad-hoc calls:

```dart
@Singleton()
class MyService {
  final HttpClient _http;
  MyService(this._http);

  Future<Map<String, dynamic>> fetchData() async {
    final response = await _http.send('GET', 'https://api.example.com/data');
    return response.json;
  }
}
```

## HttpClientBuilder

For per-client customization, inject `HttpClientBuilder` and produce a named `HttpClient`:

```dart
@Factory()
class ClientFactory {
  @Singleton()
  @Named('payments')
  HttpClient paymentsClient(@Named('payments') HttpClientBuilder builder) {
    return builder
        .defaultHeader('X-Api-Key', 'secret')
        .readTimeout(Duration(seconds: 120))
        .filter(myRetryFilter)
        .build();
  }
}
```

The builder starts pre-loaded with YAML defaults for that service name.

### Builder Methods

| Method | Description |
|--------|-------------|
| `.baseUrl(String)` | Base URL for all requests |
| `.connectTimeout(Duration)` | Connection timeout |
| `.readTimeout(Duration)` | Response read timeout |
| `.maxRedirects(int)` | Max redirect follows (default 5) |
| `.followRedirects(bool)` | Enable/disable redirects |
| `.defaultHeader(String, String)` | Header sent on every request |
| `.filter(HttpClientFilter)` | Per-client filter |
| `.build()` | Create the `HttpClient` |

## Configuration

### Global defaults

```yaml
boot:
  http:
    client:
      connect-timeout: 5s
      read-timeout: 30s
      max-redirects: 5
```

### Per-service config

```yaml
boot:
  http:
    client:
      services:
        payments:
          url: https://payments.api.com
          connect-timeout: 10s
          read-timeout: 120s
```

## Resolution Order for `@Client(name: 'payments')`

1. **Named `HttpClient` bean** — if a `@Named('payments') HttpClient` bean exists, use it
2. **Named `HttpClientBuilder`** — if registered manually, calls `.build()`
3. **Named `HttpClientServiceConfig`** — auto-created from YAML via `@EachProperty`, builds client via `HttpClientBuilder.fromConfig()`

## Error Handling

The client throws automatically on non-2xx responses:

| Exception | When |
|-----------|------|
| `HttpClientException` | Connection refused, too many redirects, timeout |
| `HttpClient4xxException` | Remote returned 4xx |
| `HttpClient5xxException` | Remote returned 5xx |

All carry `statusCode`, `body`, `headers`, and `uri`.

```dart
try {
  return await userClient.getById(id);
} on HttpClient4xxException catch (e) {
  if (e.statusCode == 404) return Response.notFound();
  rethrow;
} on HttpClient5xxException catch (e) {
  return Response(502, body: jsonEncode({'error': 'Upstream unavailable'}));
}
```

Or handle globally with an `ExceptionHandler`:

```dart
@Singleton()
class UpstreamHandler implements ExceptionHandler<HttpClient5xxException> {
  @override
  Response handle(Request req, HttpClient5xxException e) {
    return Response(502, body: jsonEncode({'error': 'Service unavailable'}));
  }
}
```

## Client Filters

Apply cross-cutting logic to outgoing requests:

```dart
@Singleton()
@ClientFilter()
class AuthFilter implements HttpClientFilter {
  final TokenService _tokens;
  AuthFilter(this._tokens);

  @override
  Future<Response> filter(MutableRequest request, ClientFilterChain chain) async {
    request.headers['Authorization'] = 'Bearer ${_tokens.current}';
    return chain.proceed(request);
  }
}
```

`@ClientFilter` beans apply to all clients globally. For per-client filters, use `HttpClientBuilder.filter()`.
