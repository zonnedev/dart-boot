// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

/// AnnotationType constants for runtime metadata queries.
const serverWebSocketAnnotationType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#ServerWebSocket');
const onOpenAnnotationType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#OnOpen');
const onMessageAnnotationType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#OnMessage');
const onCloseAnnotationType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#OnClose');
const onErrorAnnotationType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#OnError');

/// Marks a class as a WebSocket endpoint handler.
/// Implies @Singleton.
@BeanSource()
class ServerWebSocket {
  final String path;
  final List<String> protocols;
  final String? idleTimeout;
  final int? maxMessageSize;

  const ServerWebSocket(this.path, {this.protocols = const [], this.idleTimeout, this.maxMessageSize});
}

/// Method called when a new WebSocket connection is opened.
@MethodHook()
class OnOpen {
  const OnOpen();
}

/// Method called when a message is received.
@MethodHook()
class OnMessage {
  const OnMessage();
}

/// Method called when the connection is closed.
@MethodHook()
class OnClose {
  const OnClose();
}

/// Method called when an error occurs.
@MethodHook()
class OnError {
  const OnError();
}
