// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_auth_provider.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $JwtAuthProviderDefinition extends BeanDefinition {
  @override
  get beanType => JwtAuthProvider;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtAuthProvider create(BeanContainer container) =>
      JwtAuthProvider(container.get<JwtService>());
}
