import 'package:boot_core/boot_core.dart';
import 'package:boot_scheduling/boot_scheduling.dart';
import 'package:test/test.dart';

void main() {
  group('parseDuration', () {
    test('parses milliseconds', () {
      expect(parseDuration('500ms'), Duration(milliseconds: 500));
    });

    test('parses seconds', () {
      expect(parseDuration('5s'), Duration(seconds: 5));
    });

    test('parses minutes', () {
      expect(parseDuration('2m'), Duration(minutes: 2));
    });

    test('parses hours', () {
      expect(parseDuration('1h'), Duration(hours: 1));
    });

    test('parses days', () {
      expect(parseDuration('3d'), Duration(days: 3));
    });

    test('throws on invalid format', () {
      expect(() => parseDuration('abc'), throwsFormatException);
      expect(() => parseDuration('10x'), throwsFormatException);
      expect(() => parseDuration(''), throwsFormatException);
    });

    test('handles whitespace', () {
      expect(parseDuration(' 5s '), Duration(seconds: 5));
    });
  });

  group('TaskScheduler', () {
    late TaskScheduler scheduler;

    setUp(() => scheduler = TaskScheduler());
    tearDown(() => scheduler.shutdown());

    test('scheduleFixedRate executes periodically', () async {
      var count = 0;
      scheduler.scheduleFixedRate('test', Duration(milliseconds: 50), () => count++);
      await Future.delayed(Duration(milliseconds: 130));
      expect(count, greaterThanOrEqualTo(2));
    });

    test('scheduleFixedRate with initialDelay', () async {
      var count = 0;
      scheduler.scheduleFixedRate('test', Duration(milliseconds: 50), () => count++,
          initialDelay: Duration(milliseconds: 100));
      await Future.delayed(Duration(milliseconds: 80));
      expect(count, 0); // not started yet
      await Future.delayed(Duration(milliseconds: 100));
      expect(count, greaterThanOrEqualTo(1));
    });

    test('scheduleFixedDelay waits after completion', () async {
      var count = 0;
      scheduler.scheduleFixedDelay('test', Duration(milliseconds: 50), () async {
        count++;
        await Future.delayed(Duration(milliseconds: 20)); // simulate work
      });
      await Future.delayed(Duration(milliseconds: 200));
      // With 50ms delay + 20ms work = ~70ms per cycle, expect ~2-3 in 200ms
      expect(count, greaterThanOrEqualTo(2));
      expect(count, lessThanOrEqualTo(4));
    });

    test('scheduleFixedDelay with initialDelay', () async {
      var count = 0;
      scheduler.scheduleFixedDelay('test', Duration(milliseconds: 50), () async => count++,
          initialDelay: Duration(milliseconds: 100));
      await Future.delayed(Duration(milliseconds: 80));
      expect(count, 0);
      await Future.delayed(Duration(milliseconds: 150));
      expect(count, greaterThanOrEqualTo(1));
    });

    test('scheduleOnce fires once after delay', () async {
      var count = 0;
      scheduler.scheduleOnce('test', Duration(milliseconds: 50), () => count++);
      await Future.delayed(Duration(milliseconds: 30));
      expect(count, 0);
      await Future.delayed(Duration(milliseconds: 40));
      expect(count, 1);
      await Future.delayed(Duration(milliseconds: 60));
      expect(count, 1); // still 1, not repeated
    });

    test('shutdown cancels all tasks', () async {
      var count = 0;
      scheduler.scheduleFixedRate('test', Duration(milliseconds: 30), () => count++);
      await Future.delayed(Duration(milliseconds: 80));
      final countAtShutdown = count;
      scheduler.shutdown();
      await Future.delayed(Duration(milliseconds: 80));
      expect(count, countAtShutdown); // no more increments
    });
  });

  group('TaskScheduler with DI container', () {
    test('TaskScheduler as singleton in container', () {
      final container = BeanContainer();
      final scheduler = TaskScheduler();
      container.overrideWithInstance<TaskScheduler>(scheduler);

      expect(identical(container.get<TaskScheduler>(), scheduler), isTrue);
      scheduler.shutdown();
    });

    test('simulates generated scheduled task wiring', () async {
      final container = BeanContainer();
      final scheduler = TaskScheduler();
      container.overrideWithInstance<TaskScheduler>(scheduler);

      // Simulate what $configure generates:
      // container.get<TaskScheduler>().scheduleFixedRate('Job.run', parseDuration('100ms'), () => job.run());
      var ran = false;
      container.get<TaskScheduler>().scheduleFixedRate(
        'CleanupJob.clean',
        parseDuration('50ms'),
        () => ran = true,
      );

      await Future.delayed(Duration(milliseconds: 80));
      expect(ran, isTrue);
      scheduler.shutdown();
    });

    test('shutdown via container lifecycle', () async {
      final container = BeanContainer();
      final scheduler = TaskScheduler();
      container.overrideWithInstance<TaskScheduler>(scheduler);

      var count = 0;
      scheduler.scheduleFixedRate('test', Duration(milliseconds: 30), () => count++);
      await Future.delayed(Duration(milliseconds: 80));

      // Simulate app shutdown
      scheduler.shutdown();
      final countAfter = count;
      await Future.delayed(Duration(milliseconds: 80));
      expect(count, countAfter);
    });
  });
}
