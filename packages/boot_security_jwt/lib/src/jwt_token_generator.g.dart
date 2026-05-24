// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_token_generator.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtTokenGeneratorDefinition extends BeanDefinition {
  @override
  String get typeName => 'JwtTokenGenerator';

  @override
  JwtTokenGenerator create(BeanContainer container) =>
      JwtTokenGenerator(container.get<JwtConfig>());
}
