// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_authentication_provider.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $JwtAuthenticationProviderDefinition extends BeanDefinition {
  @override
  get beanType => JwtAuthenticationProvider;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  JwtAuthenticationProvider create(BeanContainer container) =>
      JwtAuthenticationProvider(
          container.get<TokenReader>(), container.get<TokenValidator>());
}
