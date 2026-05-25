import 'package:boot_core/boot_core.dart';

import 'annotations.dart';
import 'websocket_server.dart';

/// Wires @ServerWebSocket beans to the WebSocketServer at runtime.
///
/// Discovers beans with @ServerWebSocket annotation metadata,
/// reads @OnOpen/@OnMessage/@OnClose/@OnError from methodMetadata,
/// and wires them using dispatch.
class WebSocketWiringProcessor {
  final WebSocketServer _server;

  WebSocketWiringProcessor(this._server);

  /// Wire all WebSocket beans from the container.
  void wireAll(BeanContainer container) {
    final seen = <BeanDefinition>{};

    for (final entry in container.allDefinitions) {
      for (final def in entry.value) {
        if (seen.contains(def)) continue;

        final wsAnn = def.annotationMetadata.byType(serverWebSocketAnnotationType);
        if (wsAnn == null) continue;
        seen.add(def);

        final path = wsAnn.values['path'] as String;
        final protocols = (wsAnn.values['protocols'] as List?)?.cast<String>() ?? [];
        final idleTimeout = wsAnn.values['idleTimeout'] as String?;
        final maxMessageSize = wsAnn.values['maxMessageSize'] as int?;

        // Find method names from methodMetadata
        String? onOpen;
        String? onMessage;
        String? onClose;
        String? onError;

        for (final method in def.methodMetadata) {
          if (method.annotations.hasType(onOpenAnnotationType)) onOpen = method.methodName;
          if (method.annotations.hasType(onMessageAnnotationType)) onMessage = method.methodName;
          if (method.annotations.hasType(onCloseAnnotationType)) onClose = method.methodName;
          if (method.annotations.hasType(onErrorAnnotationType)) onError = method.methodName;
        }

        final instance = def.create(container);

        _server.handle(path, (session) {
          if (onOpen != null) def.dispatch(instance, onOpen!, [session]);
          if (onMessage != null) {
            session.onMessage((msg) => def.dispatch(instance, onMessage!, [session, msg]));
          }
          if (onClose != null) {
            session.onClose((code, reason) => def.dispatch(instance, onClose!, [session]));
          }
          if (onError != null) {
            session.onError((e) => def.dispatch(instance, onError!, [session, e]));
          }
        },
          protocols: protocols,
          idleTimeout: idleTimeout != null ? _parseDuration(idleTimeout) : null,
          maxMessageSize: maxMessageSize,
        );
      }
    }
  }

  Duration? _parseDuration(String value) {
    if (value.endsWith('ms')) return Duration(milliseconds: int.parse(value.substring(0, value.length - 2)));
    if (value.endsWith('s')) return Duration(seconds: int.parse(value.substring(0, value.length - 1)));
    if (value.endsWith('m')) return Duration(minutes: int.parse(value.substring(0, value.length - 1)));
    if (value.endsWith('h')) return Duration(hours: int.parse(value.substring(0, value.length - 1)));
    return null;
  }
}
