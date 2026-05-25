import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/websocket/chat_socket.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket Auth', () {
    test('WebSocket server requires auth when configured', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.authRequired, isTrue);
      });
    });

    test('WebSocket server does not require auth when disabled', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'false',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.authRequired, isFalse);
      });
    });

    test('auth providers are wired to WebSocket server', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      }, test: (client, container) async {
        final providers = container.container.getAll<AuthenticationProvider>();
        expect(providers, isNotEmpty);
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

    test('ChatSocket has correct method hooks', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final defs = container.container.getDefinitions<ChatSocket>();
        expect(defs, isNotEmpty);

        final def = defs.first;
        final methodNames = def.methodMetadata.map((m) => m.methodName).toSet();
        expect(methodNames, containsAll(['onOpen', 'onMessage', 'onClose']));
      });
    });
  });
}
