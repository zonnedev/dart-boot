// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $UploadControllerDefinition extends BeanDefinition {
  @override
  get beanType => UploadController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/upload'}),
      ];

  @override
  UploadController create(BeanContainer container) => UploadController();
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $UploadControllerRoutes implements RouteRegistration {
  final UploadController controller;
  $UploadControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'POST',
          path: '/upload/avatar',
          handler: (request) async {
            return await controller.uploadAvatar(request);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/upload'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Post'),
                {'path': '/avatar'})
          ],
        ),
      ];
}
