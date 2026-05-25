// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $DatabaseDefinition extends BeanDefinition {
  @override
  get beanType => Database;

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
              'notEnv': [],
              'property': 'pg.host',
              'beans': [],
              'missingBeans': []
            }),
      ];

  @override
  Database create(BeanContainer container) => Database(
      container.get<BootConfig>().resolvePlaceholder('\${pg.host}'),
      int.parse(
          container.get<BootConfig>().resolvePlaceholder('\${pg.port:5432}')),
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${pg.database:postgres}'),
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${pg.username:postgres}'),
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${pg.password:postgres}'));
  @override
  bool get hasPostConstruct => true;
  @override
  void postConstruct(dynamic instance) {
    (instance as Database).init();
  }

  @override
  bool get hasPreDestroy => true;
  @override
  void preDestroy(dynamic instance) => (instance as Database).close();
}
