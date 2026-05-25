// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_token_validator.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $JwtTokenValidatorDefinition extends BeanDefinition {
  @override
  get beanType => JwtTokenValidator;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtTokenValidator create(BeanContainer container) =>
      JwtTokenValidator(container.get<JwtConfig>());
}
