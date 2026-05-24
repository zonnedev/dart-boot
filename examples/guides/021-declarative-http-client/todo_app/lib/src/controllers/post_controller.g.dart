// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $PostControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'PostController';

  @override
  PostController create(BeanContainer container) =>
      PostController(container.get<PostClient>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $PostControllerRoutes implements RouteRegistration {
  final PostController controller;
  $PostControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/posts/',
          handler: (request) async {
            return await controller.list(request);
          },
        ),
        RouteEntry(
          method: 'GET',
          path: '/posts/<id>',
          handler: (request) async {
            final id = request.pathParams['id']!;
            return await controller.getById(request, id);
          },
        ),
        RouteEntry(
          method: 'POST',
          path: '/posts/',
          handler: (request) async {
            return await controller.create(request);
          },
        ),
      ];
}
