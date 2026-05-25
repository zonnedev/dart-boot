import 'package:boot_core/boot_core.dart';
import 'package:boot_scheduling/boot_scheduling.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduledWiringProcessor', () {
    late TaskScheduler scheduler;
    late ScheduledWiringProcessor processor;

    setUp(() {
      scheduler = TaskScheduler();
      processor = ScheduledWiringProcessor(scheduler);
    });

    tearDown(() => scheduler.shutdown());

    test('handles scheduledAnnotationType', () {
      expect(processor.handles, scheduledAnnotationType);
    });

    test('wires fixedRate task that executes', () async {
      var count = 0;
      final instance = _TestJob(() => count++);
      final def = _TestJobDefinition(instance);
      final method = MethodMetadata('run', [
        AnnotationValue(scheduledAnnotationType, {'fixedRate': '50ms'}),
      ]);

      processor.wire(instance, method, def);

      await Future.delayed(Duration(milliseconds: 130));
      expect(count, greaterThanOrEqualTo(2));
    });

    test('wires fixedDelay task that executes', () async {
      var count = 0;
      final instance = _TestJob(() => count++);
      final def = _TestJobDefinition(instance);
      final method = MethodMetadata('run', [
        AnnotationValue(scheduledAnnotationType, {'fixedDelay': '50ms'}),
      ]);

      processor.wire(instance, method, def);

      await Future.delayed(Duration(milliseconds: 130));
      expect(count, greaterThanOrEqualTo(2));
    });

    test('does not wire without fixedRate or fixedDelay', () async {
      var count = 0;
      final instance = _TestJob(() => count++);
      final def = _TestJobDefinition(instance);
      final method = MethodMetadata('run', [
        AnnotationValue(scheduledAnnotationType, {}),
      ]);

      processor.wire(instance, method, def);

      await Future.delayed(Duration(milliseconds: 100));
      expect(count, 0);
    });
  });
}

class _TestJob {
  final void Function() _fn;
  _TestJob(this._fn);
  void run() => _fn();
}

class _TestJobDefinition extends BeanDefinition {
  final _TestJob _instance;
  _TestJobDefinition(this._instance);

  @override
  Type get beanType => _TestJob;
  @override
  dynamic create(BeanContainer container) => _instance;
  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) async {
    (instance as _TestJob).run();
  }
}
