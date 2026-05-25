// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_socket.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $ChatSocketDefinition extends BeanDefinition {
  @override
  get beanType => ChatSocket;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/websocket/annotations.dart#ServerWebSocket'),
            {'path': '/chat/<room>', 'protocols': []}),
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
        MethodMetadata('onError', [
          const AnnotationValue(AnnotationType(
              'package:boot_http/src/websocket/annotations.dart#OnError'))
        ], [
          WebSocketSession,
          Object,
          String
        ]),
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as ChatSocket;
    switch (method) {
      case 'onOpen':
        return bean.onOpen(args[0] as WebSocketSession, args[1] as String);
      case 'onMessage':
        return bean.onMessage(
            args[0] as WebSocketSession, args[1] as String, args[2] as String);
      case 'onClose':
        return bean.onClose(args[0] as WebSocketSession, args[1] as String);
      case 'onError':
        return bean.onError(
            args[0] as WebSocketSession, args[1] as Object, args[2] as String);
      default:
        return super.dispatch(instance, method, args);
    }
  }

  @override
  ChatSocket create(BeanContainer container) =>
      ChatSocket(container.get<WebSocketServer>());
}
