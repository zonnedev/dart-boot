// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $EventsControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'EventsController';

  @override
  EventsController create(BeanContainer container) =>
      EventsController(container.get<NotificationStream>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $EventsControllerRoutes implements RouteRegistration {
  final EventsController controller;
  $EventsControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/events/time',
          handler: (request) async {
            final stream = controller.time(request);
            final body = stream.map((e) => e.encode());
            return Response(200,
                headers: {
                  'content-type': 'text/event-stream',
                  'cache-control': 'no-cache',
                  'connection': 'keep-alive'
                },
                body: await body.join());
          },
        ),
        RouteEntry(
          method: 'GET',
          path: '/events/notifications',
          handler: (request) async {
            final stream = controller.notifications(request);
            final body = stream.map((e) => e.encode());
            return Response(200,
                headers: {
                  'content-type': 'text/event-stream',
                  'cache-control': 'no-cache',
                  'connection': 'keep-alive'
                },
                body: await body.join());
          },
        ),
      ];
}
