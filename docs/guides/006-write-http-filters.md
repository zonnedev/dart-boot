# Guide 006: Write HTTP Filters

## What you'll build

Three filters that intercept every HTTP request: a request ID filter, a timing filter, and a simple rate limiter.

## What you'll learn

- How filters intercept requests before they reach controllers
- How to short-circuit a request (return early without hitting the controller)
- How to modify requests and responses
- How `@Order` controls which filter runs first
- How to test filters

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: What is a filter?

A filter sits between the client and your controller. Every request passes through all filters before reaching the controller, and every response passes back through them.

```
Client → Filter 1 → Filter 2 → Filter 3 → Controller
Client ← Filter 1 ← Filter 2 ← Filter 3 ← Controller
```

A filter can:
- **Pass through** — let the request continue to the next filter/controller
- **Short-circuit** — return a response immediately (skip the controller)
- **Modify** — add headers, log data, measure time

---

## Step 2: Create a Request ID filter

This filter adds a unique ID to every request so you can trace it through logs.

**`lib/src/filters/request_id_filter.dart`**

```dart
import 'dart:math';
import 'package:boot/boot.dart';

part 'request_id_filter.g.dart';

/// Adds a unique X-Request-Id header to every response.
/// Runs first (lowest order number = highest priority).
@ServerFilter()
@Order(1)
class RequestIdFilter implements HttpServerFilter {
  final _random = Random();

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    // Generate a unique ID for this request
    final requestId = _generateId();

    // Store it on the request so controllers can access it
    request.setAttribute('requestId', requestId);

    // Continue to the next filter (or controller)
    final response = await chain.proceed(request);

    // Add the ID to the response headers
    return Response(
      response.statusCode,
      headers: {...response.headers, 'x-request-id': requestId},
      body: response.body,
    );
  }

  String _generateId() {
    return List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();
  }
}
```

**What's happening:**

- `implements HttpServerFilter` — tells Boot this is a server filter
- `@Order(1)` — runs first (lower number = higher priority)
- `chain.proceed(request)` — passes the request to the next filter or controller
- After `proceed` returns, we have the response and can modify it (add headers)
- `request.setAttribute(...)` — stores data that controllers can read later

---

## Step 3: Create a Timing filter

Measures how long each request takes and logs it.

**`lib/src/filters/timing_filter.dart`**

```dart
import 'package:boot/boot.dart';

part 'timing_filter.g.dart';

/// Logs how long each request takes to process.
@ServerFilter()
@Order(2)
class TimingFilter implements HttpServerFilter {
  static final _log = Logger('TimingFilter');

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final stopwatch = Stopwatch()..start();

    // Let the request continue
    final response = await chain.proceed(request);

    stopwatch.stop();
    _log.info('${request.method} ${request.path}', {
      'status': response.statusCode,
      'duration_ms': stopwatch.elapsedMilliseconds,
    });

    return response;
  }
}
```

**What's happening:**

- Starts a timer before the request
- Calls `chain.proceed(request)` — this runs all remaining filters + the controller
- After it returns, the timer shows total processing time
- Logs the method, path, status, and duration

---

## Step 4: Create a Rate Limiter filter

This filter limits how many requests a client can make per minute. If they exceed the limit, it returns 429 without ever reaching the controller.

**`lib/src/filters/rate_limit_filter.dart`**

```dart
import 'package:boot/boot.dart';

part 'rate_limit_filter.g.dart';

/// Limits each IP to 60 requests per minute.
/// Returns 429 Too Many Requests if exceeded.
@ServerFilter()
@Order(0)  // runs BEFORE everything else
class RateLimitFilter implements HttpServerFilter {
  final _requests = <String, List<DateTime>>{};
  final int _maxRequests;

  RateLimitFilter(@Value('\${rate-limit.max:60}') this._maxRequests);

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final clientIp = request.headers['x-forwarded-for'] ?? 'unknown';
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));

    // Get this client's request history
    final history = _requests.putIfAbsent(clientIp, () => []);

    // Remove old entries
    history.removeWhere((t) => t.isBefore(oneMinuteAgo));

    // Check limit
    if (history.length >= _maxRequests) {
      // SHORT-CIRCUIT: return 429 without calling the controller
      return Response(429,
        headers: {
          'content-type': 'application/json',
          'retry-after': '60',
        },
        body: '{"error": "Too many requests. Limit: $_maxRequests per minute."}',
      );
    }

    // Record this request
    history.add(now);

    // Continue normally
    return chain.proceed(request);
  }
}
```

**What's happening:**

- `@Order(0)` — runs before all other filters (even before RequestIdFilter)
- Tracks requests per IP address in a sliding 1-minute window
- If the limit is exceeded, returns `429` immediately — the controller never runs
- `@Value('\${rate-limit.max:60}')` — configurable limit, defaults to 60
- This is a **short-circuit** — returning a `Response` directly instead of calling `chain.proceed()`

---

## Step 5: Configure the rate limit

**`application.yml`**

```yaml
rate-limit:
  max: 100  # 100 requests per minute per IP
```

---

## Step 6: Export and build

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/filters/request_id_filter.dart';
export 'src/filters/timing_filter.dart';
export 'src/filters/rate_limit_filter.dart';
```

```bash
boot build
boot serve
```

---

## Step 7: Test manually

```bash
# Normal request — check for x-request-id header
curl -v http://localhost:8080/todos/ 2>&1 | grep x-request-id
# x-request-id: 3a7f2b1c9e4d8f0a

# Server logs show timing:
# [INFO] TimingFilter: GET todos/ {status: 200, duration_ms: 2}
```

---

## Step 8: Write automated tests

**`test/filter_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Filters', () {
    test('RequestIdFilter adds x-request-id header', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/todos/');
        res.expectStatus(200);
        expect(res.headers['x-request-id'], isNotNull);
        expect(res.headers['x-request-id']!.length, 16);
      });
    });

    test('each request gets a unique ID', () async {
      await bootTest($configure, test: (client, container) async {
        final res1 = await client.get('/todos/');
        final res2 = await client.get('/todos/');
        expect(res1.headers['x-request-id'], isNot(res2.headers['x-request-id']));
      });
    });

    test('rate limiter blocks after limit exceeded', () async {
      await bootTest($configure, properties: {
        'rate-limit.max': '5',  // low limit for testing
      }, test: (client, container) async {
        // Make 5 requests (should all pass)
        for (var i = 0; i < 5; i++) {
          final res = await client.get('/todos/');
          res.expectStatus(200);
        }

        // 6th request should be blocked
        final blocked = await client.get('/todos/');
        blocked.expectStatus(429);
        expect(blocked.json()['error'], contains('Too many requests'));
        expect(blocked.headers['retry-after'], '60');
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 9: Filter execution order

Filters run in `@Order` sequence:

```
Request arrives
  → @Order(0) RateLimitFilter    — blocks if over limit
  → @Order(1) RequestIdFilter    — adds request ID
  → @Order(2) TimingFilter       — starts timer
  → Controller                   — handles the request
  ← @Order(2) TimingFilter       — stops timer, logs
  ← @Order(1) RequestIdFilter    — adds ID to response
  ← @Order(0) RateLimitFilter    — (nothing to do on response)
Response sent
```

If `RateLimitFilter` short-circuits (returns 429), the other filters and controller never run.

---

## What you've learned

- `HttpServerFilter` intercepts all requests
- `chain.proceed(request)` passes to the next filter/controller
- Returning a `Response` directly short-circuits the chain
- `@Order(n)` controls execution order (lower = first)
- Filters can modify both requests (setAttribute) and responses (add headers)
- `@Value` makes filter behavior configurable
- Filters run in tests too — same behavior as production

## Next steps

- [Guide 007: Add AOP Interceptors](007-add-aop-interceptors.md) — cross-cutting concerns like caching and timing at the method level
