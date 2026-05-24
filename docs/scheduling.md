# Scheduling

Run tasks periodically or on a cron schedule.

## Fixed Rate

Execute every N duration, regardless of how long the task takes:

```dart
import 'package:boot/boot.dart';
part 'cleanup_job.g.dart';

@Singleton()
class CleanupJob {
  final SessionRepository _sessions;
  CleanupJob(this._sessions);

  @Scheduled(fixedRate: '5m')  // every 5 minutes
  Future<void> cleanExpiredSessions() async {
    final expired = await _sessions.findExpired();
    await _sessions.deleteAll(expired);
    print('Cleaned ${expired.length} expired sessions');
  }
}
```

**Test:**
```dart
test('CleanupJob bean exists', () async {
  await bootTest($configure, test: (client, container) async {
    final job = container.get<CleanupJob>();
    expect(job, isNotNull);
    // In tests, scheduled methods don't auto-run — call directly
    await job.cleanExpiredSessions();
  });
});
```

## Fixed Delay

Wait N duration after the previous execution completes:

```dart
@Singleton()
class QueueProcessor {
  @Scheduled(fixedDelay: '10s')  // 10s after last run finishes
  Future<void> processNext() async {
    final item = await queue.dequeue();
    if (item != null) await process(item);
  }
}
```

## Cron Expressions

```dart
@Singleton()
class ReportGenerator {
  @Scheduled(cron: '0 8 * * MON')  // every Monday at 8:00 AM
  Future<void> generateWeeklyReport() async {
    // ...
  }

  @Scheduled(cron: '0 0 1 * *')  // 1st of every month at midnight
  Future<void> generateMonthlyReport() async {
    // ...
  }
}
```

## Initial Delay

Wait before the first execution:

```dart
@Singleton()
class WarmupTask {
  @Scheduled(fixedRate: '1m', initialDelay: '30s')  // start after 30s, then every 1m
  void refreshCache() {
    // ...
  }
}
```

## Duration Formats

| Format | Meaning |
|--------|---------|
| `500ms` | 500 milliseconds |
| `5s` | 5 seconds |
| `1m` | 1 minute |
| `2h` | 2 hours |

## Multiple Scheduled Methods

A single bean can have multiple scheduled methods:

```dart
@Singleton()
class MaintenanceService {
  @Scheduled(fixedRate: '1m')
  void healthCheck() { ... }

  @Scheduled(fixedRate: '1h')
  void compactDatabase() { ... }

  @Scheduled(cron: '0 3 * * *')  // 3 AM daily
  void fullBackup() { ... }
}
```

**Test:**
```dart
test('MaintenanceService methods callable', () async {
  await bootTest($configure, test: (client, container) async {
    final service = container.get<MaintenanceService>();
    // Call directly in tests — scheduler doesn't auto-run in test env
    service.healthCheck();
    service.compactDatabase();
  });
});
```

## Conditional Scheduling

Combine with `@Requires` to only schedule in certain environments:

```dart
@Singleton()
@Requires(notEnv: ['test'])  // don't run scheduled tasks in tests
class ProductionJobs {
  @Scheduled(fixedRate: '5m')
  void syncInventory() { ... }
}
```

**Test:**
```dart
test('ProductionJobs does not load in test env', () async {
  await bootTest($configure, test: (client, container) async {
    expect(container.has<ProductionJobs>(), isFalse);
  });
});
```
