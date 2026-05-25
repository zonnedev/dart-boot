import 'package:boot_core/boot_core.dart';

import 'annotations/event_listener.dart';
import 'events/event_bus.dart';

/// Wires @EventListener methods to the EventBus at runtime.
class EventListenerWiringProcessor implements MethodWiringProcessor {
  final EventBus _eventBus;

  EventListenerWiringProcessor(this._eventBus);

  @override
  AnnotationType get handles => eventListenerAnnotationType;

  @override
  void wire(Object instance, MethodMetadata method, BeanDefinition def) {
    _eventBus.onType(method.parameterTypes.first, (event) {
      def.dispatch(instance, method.methodName, [event]);
    });
  }
}
