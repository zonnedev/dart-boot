// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fake_email_service.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $FakeEmailServiceDefinition extends BeanDefinition {
  @override
  Type get beanType => FakeEmailService;

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
              'notEnv': ['prod'],
              'beans': [],
              'missingBeans': []
            }),
      ];

  @override
  FakeEmailService create(BeanContainer container) => FakeEmailService();
}
