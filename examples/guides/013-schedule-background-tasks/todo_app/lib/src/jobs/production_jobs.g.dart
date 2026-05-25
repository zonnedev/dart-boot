// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_jobs.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $ProductionJobsDefinition extends BeanDefinition {
  @override
  Type get beanType => ProductionJobs;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/requires.dart#Requires'),
            {
              'env': [],
              'notEnv': ['test'],
              'beans': [],
              'missingBeans': []
            }),
      ];

  @override
  List<MethodMetadata> get methodMetadata => const [
        MethodMetadata('compactDatabase', [
          const AnnotationValue(
              AnnotationType(
                  'package:boot_scheduling/src/annotations/scheduled.dart#Scheduled'),
              {'fixedRate': '1s'})
        ]),
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as ProductionJobs;
    switch (method) {
      case 'compactDatabase':
        return bean.compactDatabase();
      default:
        return super.dispatch(instance, method, args);
    }
  }

  @override
  ProductionJobs create(BeanContainer container) => ProductionJobs();
}
