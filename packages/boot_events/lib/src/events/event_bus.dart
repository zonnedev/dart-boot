import 'dart:async';

/// Publishes events to all registered listeners.
class EventBus {
  final _listeners = <Type, List<Function>>{};

  /// Register a listener for events of type [T].
  void on<T>(void Function(T event) handler) {
    _listeners.putIfAbsent(T, () => []).add(handler);
  }

  /// Register a listener by runtime type.
  void onType(Type type, Function handler) {
    _listeners.putIfAbsent(type, () => []).add(handler);
  }

  /// Publish an event to all listeners of its type.
  void publish<T>(T event) {
    final handlers = _listeners[T];
    if (handlers == null) return;
    for (final handler in List.of(handlers)) {
      handler(event);
    }
  }

  /// Publish async — waits for all listeners to complete.
  Future<void> publishAsync<T>(T event) async {
    final handlers = _listeners[T];
    if (handlers == null) return;
    for (final handler in handlers) {
      final result = handler(event);
      if (result is Future) await result;
    }
  }
}

// ─── Built-in Events ─────────────────────────────────────────────────────────

/// Emitted when the Boot application has started.
class StartupEvent {
  final Uri uri;
  StartupEvent(this.uri);
}

/// Emitted when the Boot application is shutting down.
class ShutdownEvent {
  const ShutdownEvent();
}
