# AOP (Aspect-Oriented Programming)

Compile-time proxy generation for cross-cutting concerns like caching, timing, retries, and transactions.

## How It Works

1. Define a custom annotation marked with `@Around()`
2. Implement a `MethodInterceptor` that handles the logic
3. Apply your annotation to any bean method
4. Boot generates a proxy at compile time — no runtime reflection

## Creating an Interceptor

### Step 1: Define the Annotation

```dart
import 'package:boot/boot.dart';

@Around()  // marks this as an AOP advice annotation
class Timed {
  const Timed();
}
```

### Step 2: Implement the Interceptor

```dart
import 'package:boot/boot.dart';
part 'timed_interceptor.g.dart';

@InterceptorBean(Timed)  // links this interceptor to the @Timed annotation
class TimedInterceptor implements MethodInterceptor {
  @override
  dynamic intercept(InvocationContext ctx) {
    final sw = Stopwatch()..start();
    final result = ctx.proceed();  // call the original method
    sw.stop();
    print('${ctx.methodName} took ${sw.elapsedMilliseconds}ms');
    return result;
  }
}
```

### Step 3: Use It

```dart
@Singleton()
class OrderService {
  @Timed()  // this method will be timed
  Future<Order> processOrder(String orderId) async {
    // ... business logic
  }
}
```

**Test:**
```dart
test('Timed interceptor runs', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<OrderService>();
    await service.processOrder('order-1');
    // Check stdout for timing output, or use a spy interceptor
  });
});
```

## Caching Interceptor

```dart
@Around()
class Cached {
  final Duration ttl;
  const Cached({this.ttl = const Duration(minutes: 5)});
}

@InterceptorBean(Cached)
class CacheInterceptor implements MethodInterceptor {
  final _cache = <String, _CacheEntry>{};

  @override
  dynamic intercept(InvocationContext ctx) {
    final key = '${ctx.methodName}:${ctx.args}';
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) return entry.value;

    final result = ctx.proceed();
    _cache[key] = _CacheEntry(result, DateTime.now().add(Duration(minutes: 5)));
    return result;
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

```dart
@Singleton()
class ProductService {
  @Cached()
  Future<Product> getProduct(String id) async {
    // expensive DB call — cached for 5 minutes
    return await _repo.findById(id);
  }
}
```

**Test:**
```dart
test('Cached interceptor returns cached value', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<ProductService>();
    final first = await service.getProduct('1');
    final second = await service.getProduct('1');
    expect(identical(first, second), isTrue); // same cached instance
  });
});
```

## Retry Interceptor

```dart
@Around()
class Retry {
  final int attempts;
  const Retry({this.attempts = 3});
}

@InterceptorBean(Retry)
class RetryInterceptor implements MethodInterceptor {
  @override
  dynamic intercept(InvocationContext ctx) {
    var lastError;
    for (var i = 0; i < 3; i++) {
      try {
        return ctx.proceed();
      } catch (e) {
        lastError = e;
        print('Retry ${i + 1}/3 for ${ctx.methodName}');
      }
    }
    throw lastError;
  }
}
```

**Test:**
```dart
test('Retry interceptor retries on failure', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<ExternalApiClient>();
    // If the method fails, it retries up to 3 times
    try {
      await service.callUnreliableApi();
    } catch (e) {
      // Failed after 3 attempts
    }
  });
});
```

## InvocationContext API

```dart
@override
dynamic intercept(InvocationContext ctx) {
  ctx.methodName;   // 'processOrder'
  ctx.args;         // [orderId] — positional arguments
  ctx.target;       // the bean instance
  ctx.proceed();    // call the original method (or next interceptor)
}
```

## Multiple Interceptors on One Method

```dart
@Singleton()
class PaymentService {
  @Timed()
  @Retry(attempts: 3)
  @Cached()
  Future<Receipt> charge(String customerId, double amount) async {
    // Execution order: Timed → Retry → Cached → actual method
  }
}
```

## Important Notes

- Intercepted classes must NOT be `final` (proxies subclass them)
- Only public, non-static methods can be intercepted
- The proxy is generated at compile time — zero runtime overhead for the proxy itself
- `ctx.proceed()` calls the next interceptor or the real method
- Interceptors are singletons by default (shared across all proxied calls)
