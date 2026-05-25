import 'dart:io';

import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:test/test.dart';

// --- Test fixtures ---

const _wsType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#ServerWebSocket');
const _onOpenType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#OnOpen');
const _onMessageType = AnnotationType(
    'package:boot_http/src/websocket/annotations.dart#OnMessage');

class _EchoSocket {
  void onOpen(WebSocketSession session) => session.send('welcome');
  void onMessage(WebSocketSession session, String msg) => session.send('echo:$msg');
}

class _EchoSocketDefinition extends BeanDefinition {
  @override
  get beanType => _EchoSocket;
  @override
  dynamic create(BeanContainer container) => _EchoSocket();
  @override
  List<AnnotationValue> get annotationMetadata => const [
        AnnotationValue(_wsType, {'path': '/echo'}),
      ];
  @override
  List<MethodMetadata> get methodMetadata => const [
        MethodMetadata('onOpen', [AnnotationValue(_onOpenType)], [WebSocketSession]),
        MethodMetadata('onMessage', [AnnotationValue(_onMessageType)], [WebSocketSession, String]),
      ];
  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as _EchoSocket;
    switch (method) {
      case 'onOpen':
        return bean.onOpen(args[0] as WebSocketSession);
      case 'onMessage':
        return bean.onMessage(args[0] as WebSocketSession, args[1] as String);
    }
  }
}

void _configure(BeanContainer container, BootRouter router) {
  container.register<_EchoSocket>(_EchoSocketDefinition());
}

// --- Tests ---

void main() {
  group('BootTestWebSocket (simulated)', () {
    test('receives welcome on connect', () async {
      await bootTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = client.ws('/echo');
        expect(ws.received, contains('welcome'));
        await ws.close();
      });
    });

    test('send and receive echo', () async {
      await bootTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = client.ws('/echo');
        ws.send('hello');
        expect(ws.received, contains('echo:hello'));
        await ws.close();
      });
    });

    test('isClosed after close', () async {
      await bootTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = client.ws('/echo');
        expect(ws.isClosed, isFalse);
        await ws.close();
        expect(ws.isClosed, isTrue);
      });
    });

    test('throws StateError when WS disabled', () async {
      await bootTest(_configure, properties: {
        'boot.websocket.enabled': 'false',
      }, test: (client, container) async {
        expect(() => client.ws('/echo'), throwsStateError);
      });
    });

    test('throws StateError for unknown path', () async {
      await bootTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        expect(() => client.ws('/unknown'), throwsStateError);
      });
    });
  });

  group('bootIntegrationTest', () {
    test('real HTTP request', () async {
      await bootIntegrationTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        // No HTTP routes registered, should get 404
        final res = await client.get('/hello');
        expect(res.statusCode, 404);
      });
    });

    test('real WebSocket connection', () async {
      await bootIntegrationTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final ws = await client.ws('/echo');
        await ws.messages.first; // welcome
        expect(ws.received, contains('welcome'));
        ws.send('test');
        await ws.messages.first; // echo
        expect(ws.received, contains('echo:test'));
        await ws.close();
      });
    });

    test('overrides work', () async {
      await bootIntegrationTest(_configure, properties: {
        'boot.websocket.enabled': 'true',
      }, overrides: (c) {
        c.override<_EchoSocket>(_EchoSocket());
      }, test: (client, container) async {
        expect(container.get<_EchoSocket>(), isNotNull);
      });
    });
  });

  group('BootIntegrationTestApp', () {
    final app = BootIntegrationTestApp(_configure, properties: {
      'boot.websocket.enabled': 'true',
    });

    setUpAll(() => app.start());
    tearDownAll(() => app.stop());

    test('isRunning after start', () {
      expect(app.isRunning, isTrue);
    });

    test('serverUri is valid', () {
      expect(app.serverUri.host, '127.0.0.1');
      expect(app.serverUri.port, greaterThan(0));
    });

    test('client HTTP works', () async {
      final res = await app.client.get('/anything');
      expect(res.statusCode, 404); // no routes, but server responds
    });

    test('client WebSocket works', () async {
      final ws = await app.client.ws('/echo');
      await ws.messages.first;
      expect(ws.received, contains('welcome'));
      ws.send('shared');
      await ws.messages.first;
      expect(ws.received, contains('echo:shared'));
      await ws.close();
    });

    test('container access', () {
      expect(app.container.get<_EchoSocket>(), isNotNull);
    });
  });
}
