// coverage:ignore-file
import 'dart:async';
import 'dart:math';

/// Request-scoped context using Dart Zones.
class BootContext {
  final _values = <String, dynamic>{};

  void set(String key, dynamic value) => _values[key] = value;
  dynamic get(String key) => _values[key];

  /// Run a function within this context (Zone-based).
  T run<T>(T Function() fn) => runZoned(fn, zoneValues: {_contextKey: this});

  /// Get the current context from the active Zone.
  static BootContext? get current => Zone.current[_contextKey] as BootContext?;

  static final _contextKey = Object();

  /// Convenience getters for common tracing values.
  String? get traceId => _values[BootContextKeys.traceId] as String? ??
      (_values[BootContextKeys.traceparent] as Traceparent?)?.traceId;
  String? get spanId => (_values[BootContextKeys.traceparent] as Traceparent?)?.parentId;
  Traceparent? get traceparent => _values[BootContextKeys.traceparent] as Traceparent?;
}

/// Well-known context keys.
class BootContextKeys {
  static const httpRequestMethod = 'http.method';
  static const urlPath = 'http.path';
  static const traceparent = 'traceparent';
  static const traceId = 'traceId';
}

/// W3C Traceparent header support.
class Traceparent {
  final String traceId;
  final String parentId;

  Traceparent({required this.traceId, required this.parentId});

  factory Traceparent.generate() {
    final rng = Random();
    final traceId = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
    final parentId = List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
    return Traceparent(traceId: traceId, parentId: parentId);
  }

  static Traceparent? parse(String? header) {
    if (header == null) return null;
    final parts = header.split('-');
    if (parts.length < 3) return null;
    return Traceparent(traceId: parts[1], parentId: parts[2]);
  }

  @override
  String toString() => '00-$traceId-$parentId-01';
}
