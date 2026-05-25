// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $AuthControllerDefinition extends BeanDefinition {
  @override
  get beanType => AuthController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/auth'}),
      ];

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
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/auth'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Post'),
                {'path': '/login'})
          ],
        ),
      ];
}
