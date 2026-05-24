import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/websocket/chat_socket.dart';
import 'package:test/test.dart';

void main() {
  group('ChatSocket', () {
    test('ChatSocket bean is registered', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final chat = container.get<ChatSocket>();
        expect(chat, isNotNull);
      });
    });

    test('WebSocketServer is available when enabled', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server, isNotNull);
      });
    });
  });
}
