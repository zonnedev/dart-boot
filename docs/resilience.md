# Retry & Circuit Breaker

Boot provides `@Retry` and `@CircuitBreaker` annotations for declarative HTTP client resilience.

## @Retry

Retries failed calls with exponential backoff:

```dart
@Client(name: 'payments')
abstract class PaymentsClient {
  @Get('/status')
  @Retry(attempts: 3, delay: '500ms', multiplier: 2.0)
  Future<Status> getStatus();
}
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `attempts` | 3 | Max number of attempts |
| `delay` | `500ms` | Initial delay between retries |
| `multiplier` | 2.0 | Delay multiplier (exponential backoff) |

Retry sequence with defaults: 500ms → 1s → 2s.

Retries on any exception (timeout, 5xx, connection refused).

## @CircuitBreaker

Stops calling a failing service to let it recover:

```dart
@Client(name: 'payments')
abstract class PaymentsClient {
  @Post('/charge')
  @CircuitBreaker(failureThreshold: 5, resetTimeout: '30s')
  Future<Receipt> charge(@Body() ChargeRequest req);
}
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `failureThreshold` | 5 | Failures before circuit opens |
| `resetTimeout` | `30s` | How long circuit stays open |

### States

```
CLOSED → (failures >= threshold) → OPEN → (timeout elapsed) → HALF-OPEN
   ↑                                                              │
   └──────────── success ←────────────────────────────────────────┘
                                    failure → back to OPEN
```

When open, throws `CircuitOpenException` immediately without making the call.

## Combining Both

```dart
@Post('/charge')
@Retry(attempts: 3, delay: '1s')
@CircuitBreaker(failureThreshold: 5, resetTimeout: '30s')
Future<Receipt> charge(@Body() ChargeRequest req);
```

Execution order: Circuit Breaker → Retry → HTTP call.

- If circuit is open → `CircuitOpenException` (no retry)
- If circuit is closed → retry up to 3 times
- If all retries fail → counts as 1 circuit failure
- After 5 such failures → circuit opens for 30s

## Handling CircuitOpenException

```dart
@Singleton()
class CircuitOpenHandler implements ExceptionHandler<CircuitOpenException> {
  @override
  Response handle(Request req, CircuitOpenException e) {
    return Response(503, body: jsonEncode({'error': 'Service temporarily unavailable'}));
  }
}
```

## YAML Overrides

Override annotation defaults per-service at runtime:

```yaml
boot:
  http:
    services:
      payments:
        retry:
          attempts: 5
          delay: 2s
        circuit-breaker:
          failure-threshold: 10
          reset-timeout: 60s
```

YAML values take precedence over annotation values when present.
