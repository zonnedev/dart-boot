// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_service.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtServiceDefinition extends BeanDefinition {
  @override
  String get typeName => 'JwtService';

  @override
  JwtService create(BeanContainer container) => JwtService(container
      .get<BootConfig>()
      .resolvePlaceholder('\${auth.jwt.secret:boot-secret-change-me}'));
}
