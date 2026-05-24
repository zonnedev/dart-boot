// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_auth_provider.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtAuthProviderDefinition extends BeanDefinition {
  @override
  String get typeName => 'JwtAuthProvider';

  @override
  JwtAuthProvider create(BeanContainer container) =>
      JwtAuthProvider(container.get<JwtService>());
}
