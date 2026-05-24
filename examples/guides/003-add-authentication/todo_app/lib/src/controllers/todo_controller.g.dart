// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $TodoControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'TodoController';

  @override
  TodoController create(BeanContainer container) => TodoController();
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $TodoControllerRoutes implements RouteRegistration {
  final TodoController controller;
  $TodoControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/todos/',
          handler: (request) async {
            return await controller.list(request);
          },
          metadata: [
            Secured(['isAuthenticated()'])
          ],
        ),
        RouteEntry(
          method: 'GET',
          path: '/todos/<id>',
          handler: (request) async {
            final id = request.pathParams['id']!;
            return await controller.getById(request, id);
          },
          metadata: [
            Secured(['isAuthenticated()'])
          ],
        ),
        RouteEntry(
          method: 'POST',
          path: '/todos/',
          handler: (request) async {
            return await controller.create(request);
          },
          metadata: [
            Secured(['isAuthenticated()'])
          ],
        ),
        RouteEntry(
          method: 'DELETE',
          path: '/todos/<id>',
          handler: (request) async {
            final id = request.pathParams['id']!;
            return await controller.delete(request, id);
          },
          metadata: [
            Secured(['isAuthenticated()']),
            Secured(['ROLE_ADMIN'])
          ],
        ),
      ];
}
