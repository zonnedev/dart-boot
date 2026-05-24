// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_refresh_token_generator.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtRefreshTokenGeneratorDefinition extends BeanDefinition {
  @override
  String get typeName => 'JwtRefreshTokenGenerator';

  @override
  JwtRefreshTokenGenerator create(BeanContainer container) =>
      JwtRefreshTokenGenerator(container.get<JwtConfig>());
}
