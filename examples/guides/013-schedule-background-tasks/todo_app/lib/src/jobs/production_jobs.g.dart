// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_jobs.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $ProductionJobsDefinition extends BeanDefinition {
  BeanContainer? _container;
  @override
  String get typeName => 'ProductionJobs';

  @override
  ProductionJobs create(BeanContainer container) {
    _container = container;
    return ProductionJobs();
  }

  @override
  bool get hasPostConstruct => true;
  @override
  void postConstruct(dynamic instance) {
    final scheduler = _container!.get<TaskScheduler>();
    scheduler.scheduleFixedRate(
      'ProductionJobs.compactDatabase',
      parseDuration('1h'),
      (instance as ProductionJobs).compactDatabase,
    );
  }
}
