// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_socket.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $DeviceSocketDefinition extends BeanDefinition {
  @override
  Type get beanType => DeviceSocket;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/websocket/annotations.dart#ServerWebSocket'),
            {'path': '/devices/<deviceId>', 'protocols': []}),
      ];

  @override
  List<MethodMetadata> get methodMetadata => const [
        MethodMetadata('onOpen', [
          const AnnotationValue(AnnotationType(
              'package:boot_http/src/websocket/annotations.dart#OnOpen'))
        ], [
          WebSocketSession,
          String
        ]),
        MethodMetadata('onMessage', [
          const AnnotationValue(AnnotationType(
              'package:boot_http/src/websocket/annotations.dart#OnMessage'))
        ], [
          WebSocketSession,
          String,
          String
        ]),
        MethodMetadata('onClose', [
          const AnnotationValue(AnnotationType(
              'package:boot_http/src/websocket/annotations.dart#OnClose'))
        ], [
          WebSocketSession,
          String
        ]),
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as DeviceSocket;
    switch (method) {
      case 'onOpen':
        return bean.onOpen(args[0] as WebSocketSession, args[1] as String);
      case 'onMessage':
        return bean.onMessage(
            args[0] as WebSocketSession, args[1] as String, args[2] as String);
      case 'onClose':
        return bean.onClose(args[0] as WebSocketSession, args[1] as String);
      default:
        return super.dispatch(instance, method, args);
    }
  }

  @override
  DeviceSocket create(BeanContainer container) => DeviceSocket();
}
