// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_service.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $JwtServiceDefinition extends BeanDefinition {
  @override
  get beanType => JwtService;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtService create(BeanContainer container) => JwtService(container
      .get<BootConfig>()
      .resolvePlaceholder('\${auth.jwt.secret:boot-secret-change-me}'));
}
