import 'request.dart';
import 'response.dart';

/// Handler function type for routes.
typedef RouteHandler = Future<Response> Function(Request request);

/// A single route entry with method, path, and handler.
class RouteEntry {
  final String method;
  final String path;
  final RouteHandler handler;

  const RouteEntry({
    required this.method,
    required this.path,
    required this.handler,
  });
}

/// Interface implemented by generated route registration classes.
abstract class RouteRegistration {
  List<RouteEntry> get routes;
}
