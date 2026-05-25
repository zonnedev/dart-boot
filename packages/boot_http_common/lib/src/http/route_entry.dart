// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

import 'request.dart';
import 'response.dart';

/// Handler function type for routes.
typedef RouteHandler = Future<Response> Function(Request request);

/// A single route entry with method, path, and handler.
class RouteEntry {
  final String method;
  final String path;
  final RouteHandler handler;

  /// Annotations from the controller method and class, available to filters at runtime.
  final List<AnnotationValue> metadata;

  const RouteEntry({
    required this.method,
    required this.path,
    required this.handler,
    this.metadata = const [],
  });
}

/// Interface implemented by generated route registration classes.
abstract class RouteRegistration {
  List<RouteEntry> get routes;
}
