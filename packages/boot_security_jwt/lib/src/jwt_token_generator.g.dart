// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_token_generator.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtTokenGeneratorDefinition extends BeanDefinition {
  @override
  Type get beanType => JwtTokenGenerator;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtTokenGenerator create(BeanContainer container) =>
      JwtTokenGenerator(container.get<JwtConfig>());
}
