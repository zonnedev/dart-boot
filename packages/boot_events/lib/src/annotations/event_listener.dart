// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

/// AnnotationType constant for runtime metadata queries.
const eventListenerAnnotationType = AnnotationType(
    'package:boot_events/src/annotations/event_listener.dart#EventListener');

/// Marks a method as an event listener. The method's parameter type
/// determines which events it receives.
@MethodHook()
class EventListener {
  const EventListener();
}
