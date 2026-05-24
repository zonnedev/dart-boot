// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_authentication_provider.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtAuthenticationProviderDefinition extends BeanDefinition {
  @override
  String get typeName => 'JwtAuthenticationProvider';

  @override
  JwtAuthenticationProvider create(BeanContainer container) =>
      JwtAuthenticationProvider(
          container.get<TokenReader>(), container.get<TokenValidator>());
}
