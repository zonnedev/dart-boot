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

    test('endpoint is registered at /chat/<room>', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.hasEndpoint('/chat/<room>'), isTrue);
      });
    });

    test('receives welcome message on connect', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = client.ws('/chat/general');
        expect(ws.received, contains('Welcome to room "general"!'));
        await ws.close();
      });
    });

    test('broadcast on message', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = client.ws('/chat/lobby');
        ws.send('hello everyone');
        // In unit test mode, dispatch is synchronous
        expect(ws.received, contains('hello everyone'));
        await ws.close();
      });
    });

    test('WebSocket not available when disabled', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'false',
      }, test: (client, container) async {
        expect(() => client.ws('/chat/room'), throwsStateError);
      });
    });
  });
}
