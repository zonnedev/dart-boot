import 'package:boot_core/boot_core.dart';
import 'package:boot_http/boot_http.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocketWiringProcessor', () {
    late WebSocketServer server;

    setUp(() {
      server = WebSocketServer();
    });

    test('wires endpoint from annotationMetadata', () {
      final container = BeanContainer();
      container.register<_TestSocket>(_TestSocketDefinition());

      WebSocketWiringProcessor(server).wireAll(container);

      expect(server.hasEndpoint('/test/<id>'), isTrue);
    });

    test('ignores beans without @ServerWebSocket', () {
      final container = BeanContainer();
      container.register<_PlainBean>(_PlainBeanDefinition());

      WebSocketWiringProcessor(server).wireAll(container);

      expect(server.registeredPaths, isEmpty);
    });

    test('extracts path params and passes to handler', () {
      final container = BeanContainer();
      container.register<_TestSocket>(_TestSocketDefinition());

      WebSocketWiringProcessor(server).wireAll(container);

      final match = server.matchEndpoint('/test/42');
      expect(match, isNotNull);
      expect(match!.pathParams, {'id': '42'});
    });
  });
}

// --- Test fixtures ---

class _TestSocket {
  String? lastRoom;
  void onOpen(dynamic session, String id) => lastRoom = id;
  void onMessage(dynamic session, String msg, String id) {}
}

const _wsType = AnnotationType('package:boot_http/src/websocket/annotations.dart#ServerWebSocket');

class _TestSocketDefinition extends BeanDefinition {
  @override
  Type get beanType => _TestSocket;

  @override
  dynamic create(BeanContainer container) => _TestSocket();

  @override
  List<AnnotationValue> get annotationMetadata => const [
        AnnotationValue(_wsType, {'path': '/test/<id>'}),
      ];

  @override
  List<MethodMetadata> get methodMetadata => const [
        MethodMetadata('onOpen', [
          AnnotationValue(onOpenAnnotationType),
        ], [dynamic, String]),
        MethodMetadata('onMessage', [
          AnnotationValue(onMessageAnnotationType),
        ], [dynamic, String, String]),
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as _TestSocket;
    switch (method) {
      case 'onOpen':
        return bean.onOpen(args[0], args[1] as String);
      case 'onMessage':
        return bean.onMessage(args[0], args[1] as String, args[2] as String);
    }
  }
}

class _PlainBean {}

class _PlainBeanDefinition extends BeanDefinition {
  @override
  Type get beanType => _PlainBean;
  @override
  dynamic create(BeanContainer container) => _PlainBean();
}
