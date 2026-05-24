import 'dart:async';

/// Parses duration strings like '5s', '500ms', '1m', '2h'.
Duration parseDuration(String input) {
  final match = RegExp(r'^(\d+)(ms|s|m|h|d)$').firstMatch(input.trim());
  if (match == null) throw FormatException('Invalid duration: $input');
  final value = int.parse(match.group(1)!);
  switch (match.group(2)) {
    case 'ms':
      return Duration(milliseconds: value);
    case 's':
      return Duration(seconds: value);
    case 'm':
      return Duration(minutes: value);
    case 'h':
      return Duration(hours: value);
    case 'd':
      return Duration(days: value);
    default:
      throw FormatException('Invalid duration unit: ${match.group(2)}');
  }
}

/// A scheduled task entry.
class ScheduledTask {
  final String name;
  final Timer _timer;

  ScheduledTask(this.name, this._timer);

  void cancel() => _timer.cancel();
}

/// Manages scheduled tasks.
class TaskScheduler {
  final _tasks = <ScheduledTask>[];

  /// Schedule a method at a fixed rate.
  void scheduleFixedRate(String name, Duration rate, void Function() task,
      {Duration? initialDelay}) {
    if (initialDelay != null) {
      Timer(initialDelay, () {
        task();
        _tasks.add(ScheduledTask(name, Timer.periodic(rate, (_) => task())));
      });
    } else {
      _tasks.add(ScheduledTask(name, Timer.periodic(rate, (_) => task())));
    }
  }

  /// Schedule a method with fixed delay between completions.
  void scheduleFixedDelay(String name, Duration delay, Future<void> Function() task,
      {Duration? initialDelay}) {
    void run() {
      task().then((_) => Timer(delay, run));
    }

    if (initialDelay != null) {
      Timer(initialDelay, run);
    } else {
      run();
    }
  }

  /// Schedule a one-shot task after initial delay.
  void scheduleOnce(String name, Duration delay, void Function() task) {
    Timer(delay, task);
  }

  /// Cancel all scheduled tasks.
  void shutdown() {
    for (final task in _tasks) {
      task.cancel();
    }
    _tasks.clear();
  }
}
