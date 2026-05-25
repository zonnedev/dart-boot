import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('ChatSocket Integration', () {
    test('connect and receive welcome message', () async {
      await bootIntegrationTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = await client.ws('/chat/general');
        // Wait for the welcome (second message after broadcast)
        await ws.messages.take(2).last;
        expect(ws.received, contains('Welcome to room "general"!'));
        await ws.close();
      });
    });

    test('messages are broadcast to all clients', () async {
      await bootIntegrationTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws1 = await client.ws('/chat/lobby');
        await ws1.messages.first; // wait for ws1 join broadcast
        final ws2 = await client.ws('/chat/lobby');
        await ws2.messages.take(2).last; // wait for ws2 welcome

        ws1.send('hello from ws1');
        // Wait for broadcast to arrive on both
        await ws1.messages.first;
        await ws2.messages.first;

        expect(ws1.received, contains('hello from ws1'));
        expect(ws2.received, contains('hello from ws1'));

        await ws1.close();
        await ws2.close();
      });
    });

    test('different rooms are isolated', () async {
      await bootIntegrationTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final wsA = await client.ws('/chat/room-a');
        await wsA.messages.take(2).last; // join + welcome
        final wsB = await client.ws('/chat/room-b');
        await wsB.messages.take(2).last; // join + welcome

        wsA.send('only for room-a');
        await wsA.messages.first; // wait for broadcast back

        expect(wsA.received, contains('only for room-a'));
        expect(wsB.received.where((m) => m.contains('only for room-a')), isEmpty);

        await wsA.close();
        await wsB.close();
      });
    });
  });
}
