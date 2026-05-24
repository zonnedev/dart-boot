// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hello_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $HelloControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'HelloController';

  @override
  HelloController create(BeanContainer container) => HelloController();
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $HelloControllerRoutes implements RouteRegistration {
  final HelloController controller;
  $HelloControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
    RouteEntry(
      method: 'GET',
      path: '/hello/',
      handler: (request) async {
        return await controller.hello(request);
      },
    ),
    RouteEntry(
      method: 'GET',
      path: '/hello/<name>',
      handler: (request) async {
        final name = request.pathParams['name']!;
        return await controller.greet(request, name);
      },
    ),
  ];
}
