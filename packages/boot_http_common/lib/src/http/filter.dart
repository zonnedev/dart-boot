import 'request.dart';
import 'response.dart';

/// Annotation for server-side HTTP filters.
/// Apply to a class that implements HttpServerFilter.
class ServerFilter {
  /// URL pattern to match (ant-style: /api/**, /users/*). Defaults to '/**' (all).
  final String pattern;

  /// HTTP methods to filter (empty = all methods).
  final List<String> methods;

  const ServerFilter({this.pattern = '/**', this.methods = const []});
}

/// Annotation for client-side HTTP filters.
/// Apply to a class that implements HttpClientFilter.
class ClientFilter {
  /// Service ID to filter (empty = all clients).
  final String? service;

  const ClientFilter({this.service});
}

/// Server-side filter interface.
abstract class HttpServerFilter {
  Future<Response> filter(Request request, FilterChain chain);
}

/// Client-side filter interface.
abstract class HttpClientFilter {
  Future<Response> filter(MutableRequest request, FilterChain chain);
}

/// Filter chain — call proceed() to invoke the next filter or the handler.
class FilterChain {
  final List<HttpServerFilter> _filters;
  final Future<Response> Function(Request) _handler;
  int _index = 0;

  FilterChain(this._filters, this._handler);

  Future<Response> proceed(Request request) async {
    if (_index >= _filters.length) {
      return _handler(request);
    }
    final filter = _filters[_index++];
    return filter.filter(request, this);
  }
}
