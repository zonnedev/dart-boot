import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket Auth', () {
    test('endpoint is registered', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.hasEndpoint('/chat/<room>'), isTrue);
      });
    });

    test('auth required when configured', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.authRequired, isTrue);
      });
    });

    test('authenticated user receives welcome with name', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final auth = Authentication(name: 'Alice', roles: ['user']);
        final ws = client.ws('/chat/general', authentication: auth);
        expect(ws.received, contains('Welcome, Alice! You are in room "general".'));
        await ws.close();
      });
    });

    test('message includes sender name', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final auth = Authentication(name: 'Bob', roles: ['user']);
        final ws = client.ws('/chat/lobby', authentication: auth);
        ws.send('hi there');
        expect(ws.received, contains('Bob: hi there'));
        await ws.close();
      });
    });
  });
}
