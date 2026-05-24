import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';

import 'cors.dart';
import 'static_file_handler.dart';



import 'package:boot_http_common/boot_http_common.dart';


import 'package:boot_core/boot_core.dart';
import '../health/health.dart';
import '../logging/request_logging_filter.dart';
import '../security/security.dart';
import '../security/security_filter.dart';

/// Error handler function type.
typedef ErrorHandler = Response Function(Object error, StackTrace stack);

/// Default error handler — returns 500 JSON response.
Response _defaultErrorHandler(Object error, StackTrace stack) {
  return Response(
    500,
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'error': error.toString()}),
  );
}

/// Boot's router. Collects route entries and builds a shelf Router internally.
class BootRouter {
  static final _log = Logger('BootRouter');
  final _entries = <RouteEntry>[];
  final _filters = <_FilterEntry>[];
  final _exceptionHandlers = <Type, ExceptionHandler>{};
  CorsConfiguration? _corsConfig;
  SecurityFilter? _securityFilter;
  StaticFileHandler? _staticHandler;
  RequestLoggingFilter? _requestLoggingFilter;
  final _authProviders = <AuthenticationProvider>[];
  List<AuthenticationProvider> get authProviders => _authProviders;
  final healthIndicators = <HealthIndicator>[];

  // Stack trace filtering config (defaults)
  int _stackMaxDepth = 10;
  List<String> _stackInclude = const [];
  List<String> _stackExclude = const ['dart:', 'package:shelf/', 'package:shelf_router/', '<asynchronous suspension>'];

  /// Configure stack trace filtering from BootConfig.
  void configureStackTrace({int? maxDepth, List<String>? include, List<String>? exclude}) {
    if (maxDepth != null) _stackMaxDepth = maxDepth;
    if (include != null) _stackInclude = include;
    if (exclude != null) _stackExclude = exclude;
  }

  StackTrace _filterStackTrace(StackTrace stack) {
    var frames = stack.toString().split('\n').where((f) => f.trim().isNotEmpty).toList();

    if (_stackInclude.isNotEmpty) {
      frames = frames.where((f) => _stackInclude.any((p) => f.contains(p))).toList();
    }

    if (_stackExclude.isNotEmpty) {
      frames = frames.where((f) => !_stackExclude.any((p) => f.contains(p))).toList();
    }

    frames = frames.take(_stackMaxDepth).toList();

    // Re-enumerate
    final renumbered = <String>[];
    for (var i = 0; i < frames.length; i++) {
      renumbered.add(frames[i].replaceFirst(RegExp(r'^#\d+\s+'), '#$i      '));
    }
    return StackTrace.fromString(renumbered.join('\n'));
  }

  /// Enable CORS with the given configuration.
  void enableCors(CorsConfiguration config) => _corsConfig = config;

  /// Enable static file serving.
  void enableStatic(StaticFileHandler handler) => _staticHandler = handler;

  /// Enable security with intercept-url-map rules.
  void enableSecurity(List<SecurityRuleEntry> rules, {String defaultAccess = 'isAuthenticated()'}) {
    _securityFilter = SecurityFilter(_authProviders, rules, defaultRules: [defaultAccess]);
  }

  /// Register an authentication provider.
  void addAuthenticationProvider(AuthenticationProvider provider) {
    _authProviders.add(provider);
  }

  /// Enable built-in request logging.
  void enableRequestLogging() => _requestLoggingFilter = RequestLoggingFilter();

  /// Register a health indicator.
  void addHealthIndicator(HealthIndicator indicator) => healthIndicators.add(indicator);
  ErrorHandler _errorHandler = _defaultErrorHandler;

  void add(RouteEntry entry) => _entries.add(entry);
  void addAll(List<RouteEntry> entries) => _entries.addAll(entries);

  /// Register a server filter with a path pattern.
  void addFilter(String pattern, HttpServerFilter filter, {int order = 0}) {
    _filters.add(_FilterEntry(pattern, filter, order));
    _filters.sort((a, b) => a.order.compareTo(b.order));
  }

  /// Register an exception handler for a specific type (Exception or Error).
  void addExceptionHandler<E>(ExceptionHandler<E> handler) {
    _exceptionHandlers[E] = handler;
  }

  /// Set a custom global error handler (fallback when no ExceptionHandler matches).
  void onError(ErrorHandler handler) => _errorHandler = handler;

  /// Build the internal shelf handler.
  shelf.Handler build() {
    final router = Router();

    for (final entry in _entries) {
      final shelfHandler = _wrapHandler(entry.handler, entry.path);
      // Register both with and without trailing slash
      final paths = <String>[entry.path];
      if (entry.path.endsWith('/')) {
        paths.add(entry.path.substring(0, entry.path.length - 1));
      } else {
        paths.add('${entry.path}/');
      }
      for (final path in paths) {
        switch (entry.method.toUpperCase()) {
          case 'GET':
            router.get(path, shelfHandler);
          case 'POST':
            router.post(path, shelfHandler);
          case 'PUT':
            router.put(path, shelfHandler);
          case 'DELETE':
            router.delete(path, shelfHandler);
          case 'PATCH':
            router.patch(path, shelfHandler);
        }
      }
    }

    return (shelf.Request request) async {
      // Handle CORS before route matching
      if (_corsConfig != null) {
        final origin = request.headers['origin'] ?? '';
        if (request.method == 'OPTIONS') {
          if (!_corsConfig!.isOriginAllowed(origin)) return shelf.Response(403);
          return shelf.Response(204, headers: _corsHeaders(origin));
        }
        // For actual requests, route normally then add CORS headers
        var response = await router.call(request);
        // Fallback to static files on 404
        if (response.statusCode == 404 && _staticHandler != null) {
          final staticResp = await _staticHandler!.handle(request.method, '/${request.url.path}', request.headers);
          if (staticResp != null) {
            response = shelf.Response(staticResp.status, headers: staticResp.headers, body: staticResp.body);
          }
        }
        if (!_corsConfig!.isOriginAllowed(origin)) return response;
        return response.change(headers: _corsHeaders(origin));
      }
      var response = await router.call(request);
      // Fallback to static files on 404
      if (response.statusCode == 404 && _staticHandler != null) {
        final staticResp = await _staticHandler!.handle(request.method, '/${request.url.path}', request.headers);
        if (staticResp != null) {
          response = shelf.Response(staticResp.status, headers: staticResp.headers, body: staticResp.body);
        }
      }
      return response;
    };
  }

  Map<String, String> _corsHeaders(String origin) {
    final c = _corsConfig!;
    final headers = <String, String>{
      'Access-Control-Allow-Origin': c.allowedOrigins.contains('*') ? '*' : origin,
      'Access-Control-Allow-Methods': c.allowedMethods.join(', '),
      'Access-Control-Allow-Headers': c.allowedHeaders.join(', '),
      'Access-Control-Max-Age': c.maxAge.toString(),
    };
    if (c.exposedHeaders.isNotEmpty) {
      headers['Access-Control-Expose-Headers'] = c.exposedHeaders.join(', ');
    }
    if (c.allowCredentials) {
      headers['Access-Control-Allow-Credentials'] = 'true';
    }
    return headers;
  }

  shelf.Handler _wrapHandler(RouteHandler handler, String routePath) {
    return (shelf.Request shelfRequest) async {
      // Create BootContext for this request
      final ctx = BootContext()
        ..set(BootContextKeys.httpRequestMethod, shelfRequest.method)
        ..set(BootContextKeys.urlPath, shelfRequest.url.path);

      final traceparent = Traceparent.parse(shelfRequest.headers['traceparent'])
          ?? Traceparent.generate();
      ctx.set(BootContextKeys.traceparent, traceparent);

      return ctx.run(() async {
        try {
          final request = Request(shelfRequest, pathParams: shelfRequest.params);

          // Find matching filters for this path
          final matchingFilters = <HttpServerFilter>[
            if (_securityFilter != null) _securityFilter!,
            if (_requestLoggingFilter != null) _requestLoggingFilter!,
            ..._filters
                .where((f) => _matchesPattern(f.pattern, '/$routePath', request.path))
                .map((f) => f.filter),
          ];

          // Build filter chain
          final chain = FilterChain(matchingFilters, (req) => handler(req));
          final response = await chain.proceed(request);
          return response.toShelf();
        } catch (e, stack) {
          // Log the exception with filtered stack trace
          final filteredStack = _filterStackTrace(stack);
          _log.error('${shelfRequest.method} ${shelfRequest.url}', null, e, filteredStack);

          // 1. Custom registered handlers (highest priority — user overrides)
          final handler = _exceptionHandlers[e.runtimeType];
        if (handler != null) {
          final request = Request(shelfRequest, pathParams: {});
          final response = handler.handle(request, e);
          return response.toShelf();
        }

        // 2. Built-in: HttpException maps directly to status code
        if (e is HttpException) {
          return Response(e.statusCode,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'error': e.message}),
          ).toShelf();
        }

        // 3. Built-in: common Dart exceptions → HTTP codes
        final mappedResponse = _mapDartException(e);
        if (mappedResponse != null) return mappedResponse.toShelf();

        // 4. Fallback to default error handler
        final errorResponse = _errorHandler(e, stack);
        return errorResponse.toShelf();
      }
      });
    };
  }

  Response? _mapDartException(Object e) {
    int? code;
    String? message;

    if (e is FormatException) {
      code = 400;
      message = 'Bad Request: ${e.message}';
    } else if (e is ArgumentError) {
      code = 400;
      message = 'Bad Request: ${e.message}';
    } else if (e is RangeError) {
      code = 400;
      message = 'Bad Request: ${e.message}';
    } else if (e is TypeError) {
      code = 400;
      message = 'Bad Request: invalid type';
    } else if (e is StateError) {
      code = 409;
      message = 'Conflict: ${e.message}';
    } else if (e is UnimplementedError) {
      code = 501;
      message = 'Not Implemented: ${e.message}';
    } else if (e is UnsupportedError) {
      code = 400;
      message = 'Unsupported: ${e.message}';
    } else if (e is TimeoutException) {
      code = 504;
      message = 'Gateway Timeout: ${e.message}';
    } else if (e is SocketException) {
      code = 502;
      message = 'Bad Gateway: ${e.message}';
    }

    if (code == null) return null;
    return Response(code,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'error': message}),
    );
  }

  bool _matchesPattern(String pattern, String routePath, String requestPath) {
    if (pattern == '/**' || pattern == '/*') return true;
    if (pattern.endsWith('/**')) {
      final prefix = pattern.substring(0, pattern.length - 3);
      return '/$requestPath'.startsWith(prefix);
    }
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return '/$requestPath'.startsWith(prefix);
    }
    return '/$requestPath' == pattern;
  }
}

class _FilterEntry {
  final String pattern;
  final HttpServerFilter filter;
  final int order;
  _FilterEntry(this.pattern, this.filter, this.order);
}
