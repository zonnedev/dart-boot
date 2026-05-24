# Guide 013: Schedule Background Tasks

## What you'll build

Background jobs that run automatically: a session cleanup every 5 minutes, a daily report at midnight, and a health check every 30 seconds.

## What you'll learn

- How to schedule methods with `@Scheduled`
- Fixed rate vs fixed delay vs cron expressions
- How to use initial delay
- How to make scheduled tasks conditional (only in production)
- How to test scheduled methods

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: What is scheduling?

Scheduling lets you run code automatically at intervals or specific times — without an external tool like cron. The tasks run inside your app process.

Common uses:
- Clean up expired data every few minutes
- Send daily/weekly reports
- Check health of external services
- Sync data from external APIs
- Refresh caches

---

## Step 2: Fixed rate — run every N duration

**`lib/src/jobs/cleanup_job.dart`**

```dart
import 'package:boot/boot.dart';

part 'cleanup_job.g.dart';

@Singleton()
class CleanupJob {
  static final _log = Logger('CleanupJob');

  /// Runs every 5 minutes, regardless of how long the previous run took.
  @Scheduled(fixedRate: '5m')
  Future<void> cleanExpiredSessions() async {
    _log.info('Cleaning expired sessions...');
    // In a real app: DELETE FROM sessions WHERE expires_at < NOW()
    await Future.delayed(Duration(seconds: 1)); // simulate work
    _log.info('Cleanup complete');
  }

  /// Runs every 30 seconds.
  @Scheduled(fixedRate: '30s')
  void checkExternalServices() {
    _log.debug('Health check: all services OK');
  }
}
```

**What's happening:**

- `@Scheduled(fixedRate: '5m')` — runs every 5 minutes. If the task takes 2 minutes, the next run starts 5 minutes after the PREVIOUS START (not after it finishes).
- The method can be `void` or `Future<void>` — both work.
- Multiple `@Scheduled` methods can exist on the same bean.

---

## Step 3: Fixed delay — wait N after completion

```dart
@Singleton()
class SyncJob {
  static final _log = Logger('SyncJob');

  /// Runs 10 seconds AFTER the previous execution finishes.
  /// If the sync takes 30 seconds, the next run starts 40 seconds after the previous start.
  @Scheduled(fixedDelay: '10s')
  Future<void> syncFromExternalApi() async {
    _log.info('Syncing data from external API...');
    // This might take variable time
    await Future.delayed(Duration(seconds: 5)); // simulate slow API
    _log.info('Sync complete');
  }
}
```

**Fixed rate vs fixed delay:**

| | Fixed Rate | Fixed Delay |
|---|---|---|
| Timer starts | From previous START | From previous END |
| Overlapping runs | Possible if task is slow | Never — waits for completion |
| Use when | Task must run at exact intervals | Task duration varies, avoid overlap |

---

## Step 4: Cron expressions — run at specific times

```dart
@Singleton()
class ReportJob {
  static final _log = Logger('ReportJob');

  /// Runs at midnight every day.
  @Scheduled(cron: '0 0 * * *')
  Future<void> dailyReport() async {
    _log.info('Generating daily report...');
    // Generate and email the report
  }

  /// Runs every Monday at 9:00 AM.
  @Scheduled(cron: '0 9 * * MON')
  Future<void> weeklyDigest() async {
    _log.info('Sending weekly digest...');
  }

  /// Runs on the 1st of every month at 6:00 AM.
  @Scheduled(cron: '0 6 1 * *')
  Future<void> monthlyBilling() async {
    _log.info('Processing monthly billing...');
  }
}
```

**Cron format:** `minute hour day-of-month month day-of-week`

| Expression | Meaning |
|---|---|
| `0 0 * * *` | Every day at midnight |
| `*/5 * * * *` | Every 5 minutes |
| `0 9 * * MON` | Every Monday at 9:00 AM |
| `0 6 1 * *` | 1st of every month at 6:00 AM |
| `30 14 * * MON-FRI` | Weekdays at 2:30 PM |

---

## Step 5: Initial delay — wait before first run

```dart
@Singleton()
class WarmupJob {
  /// Wait 30 seconds after startup, then run every minute.
  /// Gives the app time to fully initialize before starting heavy work.
  @Scheduled(fixedRate: '1m', initialDelay: '30s')
  void refreshCache() {
    // Rebuild cache from database
  }
}
```

**What's happening:** Without `initialDelay`, the first run happens immediately on startup. With it, the scheduler waits before the first execution.

---

## Step 6: Duration formats

| Format | Meaning |
|---|---|
| `500ms` | 500 milliseconds |
| `5s` | 5 seconds |
| `1m` | 1 minute |
| `30m` | 30 minutes |
| `2h` | 2 hours |

---

## Step 7: Conditional scheduling — only in production

You don't want cleanup jobs running during tests or development:

```dart
@Singleton()
@Requires(notEnv: ['test'])  // don't load this bean in test environment
class ProductionJobs {
  @Scheduled(fixedRate: '1h')
  Future<void> compactDatabase() async {
    // Heavy operation — only in production
  }
}
```

Or use a config flag:

```dart
@Singleton()
@Requires(property: 'jobs.enabled', value: 'true')
class ScheduledJobs {
  @Scheduled(fixedRate: '5m')
  void process() { ... }
}
```

```yaml
# application.yml
jobs:
  enabled: true

# application-test.yml
jobs:
  enabled: false
```

**Test:**

```dart
test('ProductionJobs does not load in test env', () async {
  await bootTest($configure, test: (client, container) async {
    expect(container.has<ProductionJobs>(), isFalse);
  });
});
```

---

## Step 8: Export and build

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/jobs/cleanup_job.dart';
```

```bash
boot build
boot serve
```

Server output (every 30 seconds):
```
[DEBUG] CleanupJob: Health check: all services OK
```

Every 5 minutes:
```
[INFO] CleanupJob: Cleaning expired sessions...
[INFO] CleanupJob: Cleanup complete
```

---

## Step 9: Write tests

Scheduled methods don't auto-run in tests (the scheduler isn't started). You test them by calling directly:

**`test/jobs_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/jobs/cleanup_job.dart';
import 'package:test/test.dart';

void main() {
  group('Scheduled Jobs', () {
    test('CleanupJob bean is registered', () async {
      await bootTest($configure, test: (client, container) async {
        final job = container.get<CleanupJob>();
        expect(job, isNotNull);
      });
    });

    test('cleanExpiredSessions runs without error', () async {
      await bootTest($configure, test: (client, container) async {
        final job = container.get<CleanupJob>();
        // Call directly — in tests, scheduler doesn't auto-run
        await job.cleanExpiredSessions();
        // If it didn't throw, it works
      });
    });

    test('conditional job does not load in test env', () async {
      await bootTest($configure, test: (client, container) async {
        // ProductionJobs has @Requires(notEnv: ['test'])
        // Default env in bootTest is 'test'
        expect(container.has<ProductionJobs>(), isFalse);
      });
    });
  });
}
```

---

## Step 10: Error handling in scheduled tasks

If a scheduled method throws, Boot logs the error and continues — the scheduler doesn't stop:

```dart
@Scheduled(fixedRate: '1m')
Future<void> riskyJob() async {
  try {
    await doSomethingThatMightFail();
  } catch (e) {
    _log.error('Job failed, will retry next cycle', null, e);
  }
}
```

---

## What you've learned

- `@Scheduled(fixedRate: '5m')` — run at fixed intervals
- `@Scheduled(fixedDelay: '10s')` — wait after completion before next run
- `@Scheduled(cron: '0 0 * * *')` — run at specific times
- `initialDelay` — wait before first execution
- `@Requires(notEnv: ['test'])` — disable jobs in test/dev
- Scheduled methods don't auto-run in tests — call them directly
- Errors in jobs are logged, scheduler continues

## Next steps

- [Guide 014: Publish and Subscribe Events](014-publish-and-subscribe-events.md) — decouple services with events
