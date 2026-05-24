# Logging & Tracing

Structured logging with automatic trace context propagation.

## Logger

Create a logger with a name and use it anywhere:

```dart
import 'package:boot/boot.dart';
part 'order_service.g.dart';

@Singleton()
class OrderService {
  static final _log = Logger('OrderService');

  Future<Order> createOrder(CreateOrderRequest req) async {
    _log.info('Creating order', {'customer': req.customerId, 'items': req.items.length});

    try {
      final order = await _processOrder(req);
      _log.info('Order created', {'orderId': order.id, 'total': order.total});
      return order;
    } catch (e, stack) {
      _log.error('Failed to create order', {'customer': req.customerId}, e, stack);
      rethrow;
    }
  }
}
```

**Test:**
```dart
test('OrderService logs on creation', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<OrderService>();
    // Logger output goes to stdout — verify behavior, not logs
    final order = await service.createOrder(CreateOrderRequest(...));
    expect(order, isNotNull);
  });
});
```

## Log Levels

```dart
_log.trace('Very detailed debug info');
_log.debug('Debug info for development');
_log.info('Normal operation events');
_log.warn('Something unexpected but recoverable', null, error);
_log.error('Something failed', null, error, stackTrace);
```

Configure the minimum level:

```yaml
boot:
  logging:
    level: info    # trace, debug, info, warn, error
```

## Structured Fields

Pass a map of fields for machine-parseable logs:

```dart
_log.info('Request processed', {
  'method': 'POST',
  'path': '/orders',
  'duration_ms': 42,
  'status': 201,
});
```

Output (text format):
```
2026-05-23T22:30:00.000 [INFO] OrderService: Request processed {method: POST, path: /orders, duration_ms: 42, status: 201}
```

## Log Format

```yaml
boot:
  logging:
    format: text   # human-readable (default)
    # format: json  # machine-parseable
```

JSON format output:
```json
{"timestamp":"2026-05-23T22:30:00.000","level":"INFO","logger":"OrderService","message":"Request processed","method":"POST","path":"/orders","duration_ms":42,"status":201}
```

## Request Logging

Boot automatically logs every HTTP request:

```yaml
boot:
  logging:
    request-logging: true   # default: true
```

Output:
```
2026-05-23T22:30:00.000 [INFO] HTTP: POST /orders → 201 (42ms) [trace:abc123]
```

Disable in tests:
```yaml
# application-test.yml
boot:
  logging:
    request-logging: false
```

**Test:**
```dart
test('request logging can be disabled', () async {
  await bootTest($configure, properties: {
    'boot.logging.request-logging': 'false',
  }, test: (client, container) async {
    final res = await client.get('/hello/');
    res.expectStatus(200);
    // No request log output
  });
});
```

## Tracing

Every request gets a trace context (W3C `traceparent`):

```dart
@Get('/process')
Future<Response> process(Request req) async {
  final ctx = BootContext.current!;
  final traceId = ctx.traceId;   // 32-char hex
  final spanId = ctx.spanId;     // 16-char hex

  _log.info('Processing', {'traceId': traceId});
  return Response.json({'traceId': traceId});
}
```

If the client sends a `traceparent` header, Boot continues that trace. Otherwise, it generates a new one.

**Test:**
```dart
test('trace context is available', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/process');
    res.expectStatus(200);
    expect(res.json()['traceId'], hasLength(32));
  });
});

test('trace propagation from client header', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/process', headers: {
      'traceparent': '00-abcdef1234567890abcdef1234567890-1234567890abcdef-01',
    });
    res.expectStatus(200);
    expect(res.json()['traceId'], 'abcdef1234567890abcdef1234567890');
  });
});
```

## Stack Trace Filtering

Exception stack traces are filtered to remove framework internals:

```yaml
boot:
  logging:
    stacktrace:
      filter:
        enabled: true           # false → show full raw traces
        max-depth: 10           # max frames after filtering
        exclude:                # hide frames matching these prefixes
          - dart:
          - package:shelf/
          - package:shelf_router/
        # include:              # if set, ONLY show matching frames
        #   - package:myapp/
        #   - package:boot_
```

Before filtering (63 lines):
```
#0  HelloController.hello (package:myapp/...)
#1  $HelloControllerRoutes (package:myapp/...)
#2  BootRouter._wrapHandler (package:boot_http/...)
#3  FilterChain.proceed (package:boot_http_common/...)
... 59 more lines of dart:async, dart:io, shelf internals
```

After filtering (3 lines):
```
#0  HelloController.hello (package:myapp/src/controllers/hello_controller.dart:9:5)
#1  $HelloControllerRoutes (package:myapp/src/controllers/hello_controller.g.dart:31:41)
#2  BootRouter._wrapHandler (package:boot_http/src/http/router.dart:162:70)
```

## Custom Log Handler

Replace the default console handler:

```dart
@Singleton()
class JsonFileLogHandler implements LogHandler {
  final File _file;
  JsonFileLogHandler() : _file = File('app.log');

  @override
  void handle(LogRecord record) {
    _file.writeAsStringSync(
      jsonEncode({
        'ts': record.timestamp.toIso8601String(),
        'level': record.level.name,
        'logger': record.logger,
        'msg': record.message,
        if (record.error != null) 'error': record.error.toString(),
      }) + '\n',
      mode: FileMode.append,
    );
  }
}
```

## Summary

| Config | Default | Description |
|---|---|---|
| `boot.logging.level` | `info` | Minimum log level |
| `boot.logging.format` | `text` | `text` or `json` |
| `boot.logging.request-logging` | `true` | Log every HTTP request |
| `boot.logging.stacktrace.filter.enabled` | `true` | Filter stack traces |
| `boot.logging.stacktrace.filter.max-depth` | `10` | Max frames shown |
| `boot.logging.stacktrace.filter.exclude` | `[dart:, shelf]` | Packages to hide |
