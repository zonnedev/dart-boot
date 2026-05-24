# boot_scheduling

Task scheduling for the Boot Framework.

## Features

- `@Scheduled(fixedRate: '5m')` — periodic execution
- `@Scheduled(fixedDelay: '10s')` — delay between completions
- `@Scheduled(cron: '0 0 * * *')` — cron expressions
- `initialDelay` — wait before first execution
- `parseDuration()` — parse duration strings (ms, s, m, h, d)

## Usage

```dart
@Singleton()
class CleanupJob {
  @Scheduled(fixedRate: '5m')
  Future<void> clean() async { /* ... */ }
}
```
