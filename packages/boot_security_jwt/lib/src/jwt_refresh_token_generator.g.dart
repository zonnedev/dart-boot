// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_refresh_token_generator.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $JwtRefreshTokenGeneratorDefinition extends BeanDefinition {
  @override
  get beanType => JwtRefreshTokenGenerator;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtRefreshTokenGenerator create(BeanContainer container) =>
      JwtRefreshTokenGenerator(container.get<JwtConfig>());
}
