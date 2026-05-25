// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_repository.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $TodoRepositoryDefinition extends BeanDefinition {
  @override
  get beanType => TodoRepository;

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
  TodoRepository create(BeanContainer container) =>
      TodoRepository(container.get<Database>());
  @override
  bool get hasPostConstructAsync => true;
  @override
  Future<void> postConstructAsync(dynamic instance) async {
    await (instance as TodoRepository).init();
  }
}
