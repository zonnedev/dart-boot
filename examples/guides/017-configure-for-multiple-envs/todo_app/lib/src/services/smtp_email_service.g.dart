// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smtp_email_service.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $SmtpEmailServiceDefinition extends BeanDefinition {
  @override
  get beanType => SmtpEmailService;

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
              'env': ['prod'],
              'notEnv': [],
              'beans': [],
              'missingBeans': []
            }),
      ];

  @override
  SmtpEmailService create(BeanContainer container) => SmtpEmailService();
}
