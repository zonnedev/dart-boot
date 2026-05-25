// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_config.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $JwtConfigDefinition extends BeanDefinition {
  @override
  get beanType => JwtConfig;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtConfig create(BeanContainer container) => JwtConfig(
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${boot.security.jwt.secret}'),
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${boot.security.jwt.expiration:1h}'),
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${boot.security.jwt.refresh-expiration:7d}'),
      container
          .get<BootConfig>()
          .resolvePlaceholder('\${boot.security.jwt.issuer:}'));
}
