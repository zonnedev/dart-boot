// coverage:ignore-file
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:boot_core/boot_core.dart';

/// Represents a single WebSocket connection.
class WebSocketSession {
  final WebSocket _socket;
  final String id;
  final String? subprotocol;
  final Map<String, String> headers;
  final Map<String, String> pathParams;
  final Map<String, dynamic> attributes = {};
  final dynamic authentication;

  void Function(String message)? _onMessage;
  void Function(Uint8List data)? _onBinary;
  void Function(int code, String? reason)? _onClose;
  void Function(Object error)? _onError;

  WebSocketSession(
    this._socket, {
    required this.id,
    this.subprotocol,
    this.headers = const {},
    this.pathParams = const {},
    this.authentication,
  }) {
    _socket.listen(
      (data) {
        if (data is String && _onMessage != null) {
          _onMessage!(data);
        } else if (data is List<int> && _onBinary != null) {
          _onBinary!(Uint8List.fromList(data));
        }
      },
      onDone: () => _onClose?.call(_socket.closeCode ?? 1005, _socket.closeReason),
      onError: (e) => _onError?.call(e),
    );
  }

  void onMessage(void Function(String message) handler) => _onMessage = handler;
  void onBinary(void Function(Uint8List data) handler) => _onBinary = handler;
  void onClose(void Function(int code, String? reason) handler) => _onClose = handler;
  void onError(void Function(Object error) handler) => _onError = handler;

  void send(String message) => _socket.add(message);
  void sendBytes(List<int> data) => _socket.add(data);
  void sendJson(Object data) => _socket.add(jsonEncode(data));
  void close([int code = 1000, String? reason]) => _socket.close(code, reason);

  /// Ping the client (keep-alive check).
  void ping() => _socket.add('');
}

/// Configuration for a WebSocket endpoint handler.
class WebSocketHandlerConfig {
  final List<String> protocols;
  final Duration? idleTimeout;
  final int? maxMessageSize;

  WebSocketHandlerConfig({
    this.protocols = const [],
    this.idleTimeout,
    this.maxMessageSize,
  });
}

/// Handler type for WebSocket connections.
typedef WebSocketHandler = void Function(WebSocketSession session);

/// WebSocket server — manages endpoints and connections.
class WebSocketServer {
  final Map<String, _WsEndpoint> _endpoints = {};
  final Map<String, List<WebSocketSession>> _sessions = {};
  final int maxFrameSize;
  final Duration? pingInterval;
  final List<dynamic> _authProviders = [];
  bool authRequired = false;

  WebSocketServer({this.maxFrameSize = 65536, this.pingInterval});

  /// Add an authentication provider for WebSocket upgrade validation.
  void addAuthProvider(dynamic provider) => _authProviders.add(provider);

  /// Authenticate the upgrade request. Returns authentication or null.
  Future<dynamic> _authenticate(HttpRequest request) async {
    if (!authRequired || _authProviders.isEmpty) return null;

    // Build a full auth request with all available context
    final token = request.uri.queryParameters['token'] ??
        request.headers.value('authorization')?.replaceFirst('Bearer ', '');

    // Extract client certificates if mTLS
    List<dynamic>? clientCerts;
    try {
      final cert = request.certificate;
      if (cert != null) clientCerts = [cert];
    } catch (_) {}

    final authRequest = _WsAuthRequest(
      token: token,
      headers: _extractHeaders(request.headers),
      queryParams: request.uri.queryParameters,
      clientCertificates: clientCerts,
      isTls: request.connectionInfo?.remoteAddress != null && request.certificate != null,
      remoteAddress: request.connectionInfo?.remoteAddress.address,
      path: request.uri.path,
    );

    // Try each provider
    for (final provider in _authProviders) {
      try {
        final auth = await provider.authenticate(authRequest);
        if (auth != null) return auth;
      } catch (_) {}
    }
    return null;
  }

  /// Register a handler for a WebSocket path.
  void handle(
    String path,
    WebSocketHandler handler, {
    List<String> protocols = const [],
    Duration? idleTimeout,
    int? maxMessageSize,
  }) {
    _endpoints[path] = _WsEndpoint(
      handler: handler,
      config: WebSocketHandlerConfig(
        protocols: protocols,
        idleTimeout: idleTimeout,
        maxMessageSize: maxMessageSize,
      ),
    );
  }

  /// Broadcast a message to all sessions on a path.
  void broadcast(String path, String message) {
    for (final session in _sessions[path] ?? []) {
      session.send(message);
    }
  }

  /// Broadcast binary data to all sessions on a path.
  void broadcastBytes(String path, List<int> data) {
    for (final session in _sessions[path] ?? []) {
      session.sendBytes(data);
    }
  }

  /// Get all active sessions for a path.
  List<WebSocketSession> sessions(String path) => _sessions[path] ?? [];

  /// Check if a handler is registered for the given path pattern.
  bool hasEndpoint(String path) => _endpoints.containsKey(path);

  /// Get all registered endpoint path patterns.
  Iterable<String> get registeredPaths => _endpoints.keys;

  /// Handle an incoming WebSocket upgrade request.
  Future<bool> handleUpgrade(HttpRequest request) async {
    final path = request.uri.path;
    final matchResult = _matchEndpoint(path);
    if (matchResult == null) return false;

    final (endpoint, pathParams) = matchResult;

    // Authenticate before upgrade
    dynamic auth;
    if (authRequired) {
      auth = await _authenticate(request);
      if (auth == null) {
        request.response.statusCode = 401;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error":"Unauthorized"}');
        await request.response.close();
        return true; // handled (rejected)
      }
    }

    // Negotiate subprotocol
    final requestedProtocols = request.headers['sec-websocket-protocol']
        ?.expand((h) => h.split(',').map((s) => s.trim()))
        .toList() ?? [];
    String? selectedProtocol;
    if (endpoint.config.protocols.isNotEmpty && requestedProtocols.isNotEmpty) {
      selectedProtocol = requestedProtocols
          .where((p) => endpoint.config.protocols.contains(p))
          .firstOrNull;
    }

    final socket = await WebSocketTransformer.upgrade(request);

    final ctx = BootContext()
      ..set(BootContextKeys.urlPath, path)
      ..set(BootContextKeys.traceparent,
          Traceparent.parse(request.headers.value('traceparent')) ?? Traceparent.generate());

    ctx.run(() async {
      final session = WebSocketSession(
        socket,
        id: BootContext.current!.traceparent!.parentId,
        subprotocol: selectedProtocol,
        headers: _extractHeaders(request.headers),
        pathParams: pathParams,
        authentication: auth,
      );

      _sessions.putIfAbsent(path, () => []).add(session);
      session.onClose((code, reason) => _sessions[path]?.remove(session));

      // Idle timeout
      if (endpoint.config.idleTimeout != null) {
        _setupIdleTimeout(session, endpoint.config.idleTimeout!);
      }

      endpoint.handler(session);
    });

    return true;
  }

  void _setupIdleTimeout(WebSocketSession session, Duration timeout) {
    Timer? timer;
    void resetTimer() {
      timer?.cancel();
      timer = Timer(timeout, () => session.close(1000, 'Idle timeout'));
    }
    resetTimer();
    final originalOnMessage = session._onMessage;
    session.onMessage((msg) {
      resetTimer();
      originalOnMessage?.call(msg);
    });
  }

  Map<String, String> _extractHeaders(HttpHeaders headers) {
    final map = <String, String>{};
    headers.forEach((name, values) => map[name] = values.join(', '));
    return map;
  }

  (_WsEndpoint, Map<String, String>)? _matchEndpoint(String requestPath) {
    for (final entry in _endpoints.entries) {
      final params = _extractParams(entry.key, requestPath);
      if (params != null) return (entry.value, params);
    }
    return null;
  }

  Map<String, String>? _extractParams(String pattern, String path) {
    final patternParts = pattern.split('/');
    final pathParts = path.split('/');
    if (patternParts.length != pathParts.length) return null;

    final params = <String, String>{};
    for (var i = 0; i < patternParts.length; i++) {
      if (patternParts[i].startsWith('<') && patternParts[i].endsWith('>')) {
        params[patternParts[i].substring(1, patternParts[i].length - 1)] = pathParts[i];
      } else if (patternParts[i] != pathParts[i]) {
        return null;
      }
    }
    return params;
  }
}

class _WsEndpoint {
  final WebSocketHandler handler;
  final WebSocketHandlerConfig config;
  _WsEndpoint({required this.handler, required this.config});
}

/// Auth request wrapper for WebSocket upgrade — same shape as AuthenticationRequest.
class _WsAuthRequest {
  final String? token;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final List<dynamic>? clientCertificates;
  final bool isTls;
  final String? remoteAddress;
  final String path;

  _WsAuthRequest({
    this.token,
    required this.headers,
    this.queryParams = const {},
    this.clientCertificates,
    this.isTls = false,
    this.remoteAddress,
    this.path = '',
  });

  String? get authorization => token != null ? 'Bearer $token' : headers['authorization'];
  String get method => 'GET'; // WebSocket upgrade is always GET
}
