// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_config.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $JwtConfigDefinition extends BeanDefinition {
  @override
  String get typeName => 'JwtConfig';

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
