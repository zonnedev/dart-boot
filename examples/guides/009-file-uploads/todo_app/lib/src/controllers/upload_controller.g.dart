// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $UploadControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'UploadController';

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
    ),
  ];
}
