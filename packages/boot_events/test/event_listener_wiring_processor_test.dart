import 'package:boot_core/boot_core.dart';
import 'package:boot_events/boot_events.dart';
import 'package:test/test.dart';

void main() {
  group('EventListenerWiringProcessor', () {
    late EventBus eventBus;
    late EventListenerWiringProcessor processor;

    setUp(() {
      eventBus = EventBus();
      processor = EventListenerWiringProcessor(eventBus);
    });

    test('handles eventListenerAnnotationType', () {
      expect(processor.handles, eventListenerAnnotationType);
    });

    test('wires listener that receives events', () {
      final received = <String>[];
      final instance = _TestListener((e) => received.add(e));
      final def = _TestListenerDefinition(instance);
      final method = MethodMetadata('onUserCreated', [
        AnnotationValue(eventListenerAnnotationType),
      ], [String]);

      processor.wire(instance, method, def);

      eventBus.publish('hello');
      expect(received, ['hello']);
    });

    test('only receives events of matching type', () {
      final received = <String>[];
      final instance = _TestListener((e) => received.add(e as String));
      final def = _TestListenerDefinition(instance);
      final method = MethodMetadata('onString', [
        AnnotationValue(eventListenerAnnotationType),
      ], [String]);

      processor.wire(instance, method, def);

      eventBus.publish(42); // int, not String
      eventBus.publish('match');
      expect(received, ['match']);
    });
  });
}

class _TestListener {
  final void Function(dynamic) _fn;
  _TestListener(this._fn);
  void onUserCreated(dynamic event) => _fn(event);
  void onString(dynamic event) => _fn(event);
}

class _TestListenerDefinition extends BeanDefinition {
  final _TestListener _instance;
  _TestListenerDefinition(this._instance);

  @override
  Type get beanType => _TestListener;
  @override
  dynamic create(BeanContainer container) => _instance;
  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as _TestListener;
    switch (method) {
      case 'onUserCreated':
        return bean.onUserCreated(args[0]);
      case 'onString':
        return bean.onString(args[0]);
    }
  }
}
