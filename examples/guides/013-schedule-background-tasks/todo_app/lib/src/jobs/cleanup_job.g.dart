// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleanup_job.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $CleanupJobDefinition extends BeanDefinition {
  BeanContainer? _container;
  @override
  String get typeName => 'CleanupJob';

  @override
  CleanupJob create(BeanContainer container) {
    _container = container;
    return CleanupJob();
  }

  @override
  bool get hasPostConstruct => true;
  @override
  void postConstruct(dynamic instance) {
    final scheduler = _container!.get<TaskScheduler>();
    scheduler.scheduleFixedRate('CleanupJob.cleanExpiredSessions',
        parseDuration('5m'), (instance as CleanupJob).cleanExpiredSessions);
    scheduler.scheduleFixedRate('CleanupJob.checkExternalServices',
        parseDuration('30s'), (instance as CleanupJob).checkExternalServices);
  }
}
