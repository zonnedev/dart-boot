// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mongo_token_store.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $MongoTokenStoreDefinition extends BeanDefinition {
  @override
  Type get beanType => MongoTokenStore;

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
              'property': 'mongo.enabled',
              'value': 'true',
              'beans': [],
              'missingBeans': [null]
            }),
      ];

  @override
  MongoTokenStore create(BeanContainer container) => MongoTokenStore();
}
