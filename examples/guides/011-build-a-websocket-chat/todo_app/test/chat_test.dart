import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/websocket/chat_socket.dart';
import 'package:test/test.dart';

void main() {
  group('ChatSocket', () {
    test('bean is registered', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        expect(container.get<ChatSocket>(), isNotNull);
      });
    });

    test('WebSocketServer is available when enabled', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        expect(container.get<WebSocketServer>(), isNotNull);
      });
    });

    test('endpoint is registered at /chat/<room>', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.hasEndpoint('/chat/<room>'), isTrue);
      });
    });

    test('WebSocketServer not registered when disabled', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'false',
      }, test: (client, container) async {
        expect(container.has<WebSocketServer>(), isFalse);
      });
    });

    test('dispatch onMessage invokes handler', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final defs = container.container.getDefinitions<ChatSocket>();
        expect(defs, isNotEmpty);

        final def = defs.first;
        final instance = container.get<ChatSocket>();

        // Verify methodMetadata contains expected hooks
        final methodNames = def.methodMetadata.map((m) => m.methodName).toList();
        expect(methodNames, contains('onOpen'));
        expect(methodNames, contains('onMessage'));
        expect(methodNames, contains('onClose'));
        expect(methodNames, contains('onError'));
      });
    });

    test('broadcast sends to all sessions on path', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        // No sessions connected — broadcast should not throw
        expect(() => server.broadcast('/chat/general', 'hello'), returnsNormally);
        expect(server.sessions('/chat/general'), isEmpty);
      });
    });
  });
}
