# HTTP Filters

Filters intercept requests before they reach controllers and responses before they're sent. Use them for logging, auth, rate limiting, header injection, etc.

## Server Filters

```dart
import 'package:boot/boot.dart';
part 'timing_filter.g.dart';

@ServerFilter()
@Order(1)  // lower = runs first
class TimingFilter implements HttpServerFilter {
  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final sw = Stopwatch()..start();
    final response = await chain.proceed(request);
    sw.stop();
    print('${request.method} ${request.path} → ${sw.elapsedMilliseconds}ms');
    return response;
  }
}
```

**Test:**
```dart
test('TimingFilter runs on every request', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/hello/');
    res.expectStatus(200);
    // TimingFilter logged the request (check stdout or use a spy)
  });
});
```

## Filter Chain

Filters form a chain. Call `chain.proceed(request)` to pass to the next filter (or the controller). Return early to short-circuit:

```dart
@ServerFilter()
@Order(0)  // runs before everything
class ApiKeyFilter implements HttpServerFilter {
  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final apiKey = request.headers['x-api-key'];
    if (apiKey == null || apiKey != 'secret-key') {
      return Response(403, body: '{"error":"Invalid API key"}',
          headers: {'content-type': 'application/json'});
    }
    return chain.proceed(request); // continue to next filter/controller
  }
}
```

**Test:**
```dart
test('ApiKeyFilter blocks without key', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/api/data');
    res.expectStatus(403);
    expect(res.json()['error'], 'Invalid API key');
  });
});

test('ApiKeyFilter passes with valid key', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/api/data', headers: {'x-api-key': 'secret-key'});
    res.expectStatus(200);
  });
});
```

## Filter Ordering with @Order

Lower values execute first:

```dart
@ServerFilter()
@Order(0)   // 1st: check API key
class ApiKeyFilter implements HttpServerFilter { ... }

@ServerFilter()
@Order(1)   // 2nd: log request
class LoggingFilter implements HttpServerFilter { ... }

@ServerFilter()
@Order(10)  // 3rd: add response headers
class CorsHeaderFilter implements HttpServerFilter { ... }
```

Filters without `@Order` default to 0.

## Path-Specific Filters

Register filters for specific URL patterns:

```dart
// In Boot.run or a configuration bean
router.addFilter('/api/**', apiKeyFilter, order: 0);
router.addFilter('/admin/**', adminAuthFilter, order: 0);
```

Pattern matching:
- `/api/**` — matches `/api/users`, `/api/orders/1`, etc.
- `/admin/*` — matches `/admin/dashboard` but not `/admin/users/1`
- `/health` — exact match only

## Modifying Requests

Filters can modify the request before passing it along:

```dart
@ServerFilter()
class RequestIdFilter implements HttpServerFilter {
  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    request.setAttribute('requestId', generateId());
    return chain.proceed(request);
  }
}
```

**Test:**
```dart
test('RequestIdFilter sets attribute', () async {
  await bootTest($configure, test: (client, container) async {
    // The controller can access request.getAttribute<String>('requestId')
    final res = await client.get('/debug/request-id');
    res.expectStatus(200);
    expect(res.body, isNotEmpty); // returns the generated ID
  });
});
```

## Modifying Responses

```dart
@ServerFilter()
class SecurityHeadersFilter implements HttpServerFilter {
  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final response = await chain.proceed(request);
    // Can't modify Response directly (immutable), but can wrap
    return Response(response.statusCode,
      headers: {
        ...response.headers,
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
      },
      body: response.body,
    );
  }
}
```

**Test:**
```dart
test('SecurityHeadersFilter adds headers', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/hello/');
    expect(res.headers['x-content-type-options'], 'nosniff');
    expect(res.headers['x-frame-options'], 'DENY');
  });
});
```

## Client Filters

Filters for outgoing HTTP client requests:

```dart
@ClientFilter()
class AuthTokenClientFilter implements HttpClientFilter {
  final TokenService _tokens;
  AuthTokenClientFilter(this._tokens);

  @override
  Future<ClientResponse> filter(MutableRequest request, ClientFilterChain chain) async {
    final token = await _tokens.getAccessToken();
    request.header('Authorization', 'Bearer $token');
    return chain.proceed(request);
  }
}
```

**Test:**
```dart
test('Client filter adds auth header', () async {
  await bootTest($configure, overrides: (c) {
    c.override<TokenService>(FakeTokenService('test-token'));
  }, test: (client, container) async {
    final httpClient = container.get<HttpClient>();
    // When httpClient makes a request, AuthTokenClientFilter adds the header
  });
});
```

## Summary

| Concept | Description |
|---|---|
| `HttpServerFilter` | Intercepts incoming requests |
| `HttpClientFilter` | Intercepts outgoing client requests |
| `FilterChain.proceed()` | Pass to next filter or controller |
| Return `Response` early | Short-circuit (skip controller) |
| `@Order(n)` | Lower = runs first |
| Path patterns | `/**` recursive, `/*` single level |
