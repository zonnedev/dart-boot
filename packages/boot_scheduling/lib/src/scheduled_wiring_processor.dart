import 'package:boot_core/boot_core.dart';

import 'annotations/scheduled.dart';
import 'scheduling/task_scheduler.dart';

/// Wires @Scheduled methods to the TaskScheduler at runtime.
class ScheduledWiringProcessor implements MethodWiringProcessor {
  final TaskScheduler _scheduler;

  ScheduledWiringProcessor(this._scheduler);

  @override
  AnnotationType get handles => scheduledAnnotationType;

  @override
  void wire(Object instance, MethodMetadata method, BeanDefinition def) {
    final ann = method.annotations.byType(scheduledAnnotationType);
    if (ann == null) return;

    final fixedRate = ann.values['fixedRate'] as String?;
    final fixedDelay = ann.values['fixedDelay'] as String?;
    final initialDelay = ann.values['initialDelay'] as String?;
    final name = '${def.beanType}.${method.methodName}';

    final initDelay = initialDelay != null && initialDelay.isNotEmpty
        ? parseDuration(initialDelay)
        : null;

    if (fixedRate != null && fixedRate.isNotEmpty) {
      _scheduler.scheduleFixedRate(
        name,
        parseDuration(fixedRate),
        () => def.dispatch(instance, method.methodName, []),
        initialDelay: initDelay,
      );
    } else if (fixedDelay != null && fixedDelay.isNotEmpty) {
      _scheduler.scheduleFixedDelay(
        name,
        parseDuration(fixedDelay),
        () => def.dispatch(instance, method.methodName, []),
        initialDelay: initDelay,
      );
    }
  }
}
