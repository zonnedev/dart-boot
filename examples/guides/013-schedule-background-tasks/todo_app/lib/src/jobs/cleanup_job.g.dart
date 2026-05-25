// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleanup_job.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $CleanupJobDefinition extends BeanDefinition {
  @override
  Type get beanType => CleanupJob;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  List<MethodMetadata> get methodMetadata => const [
        MethodMetadata('cleanExpiredSessions', [
          const AnnotationValue(
              AnnotationType(
                  'package:boot_scheduling/src/annotations/scheduled.dart#Scheduled'),
              {'fixedRate': '5m'})
        ]),
        MethodMetadata('checkExternalServices', [
          const AnnotationValue(
              AnnotationType(
                  'package:boot_scheduling/src/annotations/scheduled.dart#Scheduled'),
              {'fixedRate': '30s'})
        ]),
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as CleanupJob;
    switch (method) {
      case 'cleanExpiredSessions':
        return bean.cleanExpiredSessions();
      case 'checkExternalServices':
        return bean.checkExternalServices();
      default:
        return super.dispatch(instance, method, args);
    }
  }

  @override
  CleanupJob create(BeanContainer container) => CleanupJob();
}
