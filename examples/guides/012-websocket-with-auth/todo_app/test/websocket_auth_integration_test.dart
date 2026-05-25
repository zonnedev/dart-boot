import 'dart:io';

import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket Auth Integration', () {
    test('unauthenticated connection rejected when auth required', () async {
      await bootIntegrationTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      }, test: (client, container) async {
        final uri = client.serverUri.replace(scheme: 'ws', path: '/chat/room');
        // Server responds with 401 and closes connection
        expect(
          () => WebSocket.connect(uri.toString()),
          throwsA(anything),
        );
      });
    });
  });
}
