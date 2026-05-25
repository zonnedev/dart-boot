// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redis_token_store.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $RedisTokenStoreDefinition extends BeanDefinition {
  @override
  get beanType => RedisTokenStore;

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
              'property': 'redis.enabled',
              'value': 'true',
              'beans': [],
              'missingBeans': []
            }),
      ];

  @override
  RedisTokenStore create(BeanContainer container) => RedisTokenStore();
}
