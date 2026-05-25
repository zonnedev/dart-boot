// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_refresh_token_generator.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtRefreshTokenGeneratorDefinition extends BeanDefinition {
  @override
  Type get beanType => JwtRefreshTokenGenerator;

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
