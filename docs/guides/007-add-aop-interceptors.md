# Guide 007: Add AOP Interceptors

## What you'll build

Two interceptors: `@Timed` (logs how long a method takes) and `@Cached` (caches method results to avoid repeated work).

## What you'll learn

- What AOP (Aspect-Oriented Programming) is and why it's useful
- How to create a custom annotation
- How to implement a `MethodInterceptor`
- How Boot generates proxies at compile time
- How to test intercepted methods

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: What is AOP?

AOP lets you add behavior to methods **without modifying them**. Instead of writing timing/caching/retry logic inside every method, you write it once as an interceptor and apply it with an annotation.

Without AOP:
```dart
Future<Product> getProduct(String id) async {
  final sw = Stopwatch()..start();       // timing logic mixed in
  final cached = _cache[id];             // caching logic mixed in
  if (cached != null) return cached;
  final product = await _repo.findById(id);
  _cache[id] = product;                  // more caching logic
  sw.stop();
  print('getProduct took ${sw.elapsedMilliseconds}ms');  // more timing
  return product;
}
```

With AOP:
```dart
@Timed()
@Cached()
Future<Product> getProduct(String id) async {
  return await _repo.findById(id);  // just the business logic
}
```

The timing and caching happen automatically, defined once in interceptors.

---

## Step 2: Create the @Timed annotation

An annotation is just a class with `const` constructor, marked with `@Around()`:

**`lib/src/aop/timed.dart`**

```dart
import 'package:boot/boot.dart';

/// Apply to any method to log its execution time.
@Around()
class Timed {
  const Timed();
}
```

**What's happening:** `@Around()` tells Boot "this annotation triggers an interceptor." When Boot sees `@Timed()` on a method, it generates a proxy that wraps the method call.

---

## Step 3: Implement the Timed interceptor

**`lib/src/aop/timed_interceptor.dart`**

```dart
import 'package:boot/boot.dart';

part 'timed_interceptor.g.dart';

/// Logs execution time for any method annotated with @Timed().
@InterceptorBean(Timed)
class TimedInterceptor implements MethodInterceptor {
  static final _log = Logger('Timed');

  @override
  dynamic intercept(InvocationContext ctx) {
    final sw = Stopwatch()..start();
    final result = ctx.proceed();  // call the actual method
    sw.stop();
    _log.info('${ctx.methodName}', {'duration_ms': sw.elapsedMilliseconds});
    return result;
  }
}
```

**What's happening:**

- `@InterceptorBean(Timed)` — links this interceptor to the `@Timed` annotation
- `implements MethodInterceptor` — the interface Boot expects
- `ctx.proceed()` — calls the original method (or the next interceptor if there are multiple)
- `ctx.methodName` — the name of the method being called
- Everything before `proceed()` runs before the method; everything after runs after

---

## Step 4: Create the @Cached annotation and interceptor

**`lib/src/aop/cached.dart`**

```dart
import 'package:boot/boot.dart';

/// Apply to any method to cache its return value.
/// Subsequent calls with the same arguments return the cached result.
@Around()
class Cached {
  const Cached();
}
```

**`lib/src/aop/cached_interceptor.dart`**

```dart
import 'package:boot/boot.dart';

part 'cached_interceptor.g.dart';

/// Caches method results based on method name + arguments.
@InterceptorBean(Cached)
class CachedInterceptor implements MethodInterceptor {
  final _cache = <String, dynamic>{};

  @override
  dynamic intercept(InvocationContext ctx) {
    // Build a cache key from method name + arguments
    final key = '${ctx.methodName}:${ctx.args}';

    // Return cached value if available
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    // Call the real method
    final result = ctx.proceed();

    // Cache the result
    _cache[key] = result;
    return result;
  }

  /// Clear the cache (useful for testing).
  void clear() => _cache.clear();
}
```

---

## Step 5: Use the annotations

**`lib/src/services/product_service.dart`**

```dart
import 'package:boot/boot.dart';
import '../aop/timed.dart';
import '../aop/cached.dart';

part 'product_service.g.dart';

@Singleton()
class ProductService {
  var _callCount = 0;

  /// This method is both timed and cached.
  /// First call: executes and caches. Subsequent calls: returns cached value instantly.
  @Timed()
  @Cached()
  Future<Map<String, dynamic>> getProduct(String id) async {
    _callCount++;
    // Simulate slow database call
    await Future.delayed(Duration(milliseconds: 50));
    return {'id': id, 'name': 'Product $id', 'price': 9.99};
  }

  /// How many times the real method was called (for testing).
  int get callCount => _callCount;
}
```

**What's happening:**

- `@Timed()` — logs execution time
- `@Cached()` — caches the result
- Execution order: Timed starts timer → Cached checks cache → (miss) → real method runs → Cached stores result → Timed logs duration
- Second call: Timed starts timer → Cached finds cached value → returns immediately → Timed logs (very fast)

---

## Step 6: Create a controller to demonstrate

**`lib/src/controllers/product_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../services/product_service.dart';

part 'product_controller.g.dart';

@Controller('/products')
class ProductController {
  final ProductService _service;
  ProductController(this._service);

  @Get('/<id>')
  Future<Response> get(Request request, @PathParam() String id) async {
    final product = await _service.getProduct(id);
    return Response.json(product);
  }
}
```

---

## Step 7: Export, build, and test

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/aop/timed.dart';
export 'src/aop/timed_interceptor.dart';
export 'src/aop/cached.dart';
export 'src/aop/cached_interceptor.dart';
export 'src/services/product_service.dart';
export 'src/controllers/product_controller.dart';
```

```bash
boot build
boot serve
```

**Test manually:**

```bash
# First call — takes ~50ms (real method runs)
curl http://localhost:8080/products/42

# Second call — instant (cached)
curl http://localhost:8080/products/42
```

Server logs:
```
[INFO] Timed: getProduct {duration_ms: 52}
[INFO] Timed: getProduct {duration_ms: 0}
```

---

## Step 8: Write automated tests

**`test/aop_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/product_service.dart';
import 'package:test/test.dart';

void main() {
  group('AOP Interceptors', () {
    test('@Cached returns same result without re-executing', () async {
      await bootTest($configure, test: (client, container) async {
        final service = container.get<ProductService>();

        // First call — executes the method
        final result1 = await service.getProduct('1');
        expect(result1['id'], '1');
        expect(service.callCount, 1);

        // Second call — returns cached, method not called again
        final result2 = await service.getProduct('1');
        expect(result2['id'], '1');
        expect(service.callCount, 1);  // still 1!
      });
    });

    test('@Cached uses different cache per arguments', () async {
      await bootTest($configure, test: (client, container) async {
        final service = container.get<ProductService>();

        await service.getProduct('1');
        await service.getProduct('2');  // different arg = cache miss
        expect(service.callCount, 2);

        await service.getProduct('1');  // cached
        expect(service.callCount, 2);   // still 2
      });
    });

    test('endpoint returns product', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/products/42');
        res.expectStatus(200);
        expect(res.json()['id'], '42');
        expect(res.json()['name'], 'Product 42');
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 9: How it works under the hood

When you annotate a method with `@Timed()` or `@Cached()`, Boot's code generator:

1. Detects the `@Around` annotation on `Timed`/`Cached`
2. Generates a **proxy class** that extends your service
3. The proxy overrides the annotated methods
4. Each overridden method builds an `InvocationContext` and calls the interceptor chain
5. The interceptor calls `ctx.proceed()` which eventually calls your real method

You never see the proxy — Boot wires it automatically. The only requirement: **your class must not be `final`** (because the proxy subclasses it).

---

## Step 10: Multiple interceptors on one method

When multiple interceptors apply, they form a chain:

```dart
@Timed()      // outer — runs first and last
@Cached()     // inner — runs second
Future<Product> getProduct(String id) async { ... }
```

Execution:
```
TimedInterceptor.intercept()
  → starts timer
  → ctx.proceed()
    → CachedInterceptor.intercept()
      → checks cache
      → ctx.proceed()
        → real getProduct() runs
      → stores in cache
      → returns result
  → stops timer, logs
  → returns result
```

---

## Important rules

- Intercepted classes must **not** be `final`
- Only **public, non-static** methods can be intercepted
- The proxy is generated at **compile time** — no runtime reflection
- Interceptors are singletons — shared across all calls
- `ctx.proceed()` must be called exactly once (or not at all, for short-circuit like caching)

---

## What you've learned

- `@Around()` marks an annotation as AOP advice
- `@InterceptorBean(Annotation)` links an interceptor to its annotation
- `MethodInterceptor.intercept()` wraps the method call
- `ctx.proceed()` calls the real method (or next interceptor)
- Multiple interceptors chain together
- Boot generates proxies at compile time — zero runtime cost
- Great for: timing, caching, retries, logging, transactions

## Next steps

- [Guide 008: Serve Static Files](008-serve-static-files.md) — serve your frontend from Boot
