// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $HealthControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'HealthController';

  @override
  HealthController create(BeanContainer container) => HealthController();
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $HealthControllerRoutes implements RouteRegistration {
  final HealthController controller;
  $HealthControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/health/',
          handler: (request) async {
            return await controller.health(request);
          },
        ),
      ];
}
