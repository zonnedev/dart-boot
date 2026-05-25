// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $TodoControllerDefinition extends BeanDefinition {
  @override
  get beanType => TodoController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/todos'}),
        const AnnotationValue(
            AnnotationType('package:boot_security/src/secured.dart#Secured'), {
          'value': ['isAuthenticated()']
        }),
      ];

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
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/todos'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_security/src/secured.dart#Secured'),
                {
                  'value': ['isAuthenticated()']
                }),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/'})
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
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/todos'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_security/src/secured.dart#Secured'),
                {
                  'value': ['isAuthenticated()']
                }),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/<id>'})
          ],
        ),
        RouteEntry(
          method: 'POST',
          path: '/todos/',
          handler: (request) async {
            return await controller.create(request);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/todos'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_security/src/secured.dart#Secured'),
                {
                  'value': ['isAuthenticated()']
                }),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Post'),
                {'path': '/'})
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
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/todos'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_security/src/secured.dart#Secured'),
                {
                  'value': ['isAuthenticated()']
                }),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Delete'),
                {'path': '/<id>'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_security/src/secured.dart#Secured'),
                {
                  'value': ['ROLE_ADMIN']
                })
          ],
        ),
      ];
}
