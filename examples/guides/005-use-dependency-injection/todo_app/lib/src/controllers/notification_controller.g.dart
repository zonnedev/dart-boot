// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $NotificationControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'NotificationController';

  @override
  NotificationController create(BeanContainer container) =>
      NotificationController(container.get<NotificationDispatcher>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $NotificationControllerRoutes implements RouteRegistration {
  final NotificationController controller;
  $NotificationControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
    RouteEntry(
      method: 'POST',
      path: '/notifications/broadcast',
      handler: (request) async {
        return await controller.broadcast(request);
      },
    ),
  ];
}
