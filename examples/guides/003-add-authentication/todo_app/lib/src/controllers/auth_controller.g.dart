// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $AuthControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'AuthController';

  @override
  AuthController create(BeanContainer container) => AuthController(
      container.get<TokenGenerator>(), container.get<RefreshTokenGenerator>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $AuthControllerRoutes implements RouteRegistration {
  final AuthController controller;
  $AuthControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'POST',
          path: '/auth/login',
          handler: (request) async {
            return await controller.login(request);
          },
        ),
      ];
}
