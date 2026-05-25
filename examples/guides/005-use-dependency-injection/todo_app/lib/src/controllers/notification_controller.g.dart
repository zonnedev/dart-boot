// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $NotificationControllerDefinition extends BeanDefinition {
  @override
  get beanType => NotificationController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/notifications'}),
      ];

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
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/notifications'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Post'),
                {'path': '/broadcast'})
          ],
        ),
      ];
}
