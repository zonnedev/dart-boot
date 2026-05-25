// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_memory_token_store.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $InMemoryTokenStoreDefinition extends BeanDefinition {
  @override
  Type get beanType => InMemoryTokenStore;

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
              'beans': [],
              'missingBeans': [null]
            }),
      ];

  @override
  InMemoryTokenStore create(BeanContainer container) => InMemoryTokenStore();
}
