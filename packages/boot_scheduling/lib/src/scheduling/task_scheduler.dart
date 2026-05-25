import 'dart:async';

export 'package:boot_core/boot_core.dart' show parseDuration;

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
