import 'dart:async';
import 'dart:io';

import 'package:boot/boot.dart';

/// Test WebSocket connection — works in both unit (simulated) and integration (real) mode.
class BootTestWebSocket {
  final Stream<String> _incoming;
  final void Function(String) _sendFn;
  final Future<void> Function([int code]) _closeFn;
  final List<String> _received = [];
  late final StreamSubscription<String> _sub;
  final _messages = StreamController<String>.broadcast();
  bool _closed = false;

  BootTestWebSocket._({
    required Stream<String> incoming,
    required void Function(String) send,
    required Future<void> Function([int code]) close,
  })  : _incoming = incoming,
        _sendFn = send,
        _closeFn = close {
    _sub = _incoming.listen((msg) {
      _received.add(msg);
      _messages.add(msg);
    }, onDone: () => _closed = true);
  }

  /// Create from a real dart:io WebSocket (integration mode).
  factory BootTestWebSocket.fromWebSocket(WebSocket ws) {
    final controller = StreamController<String>.broadcast();
    ws.listen((data) {
      if (data is String) controller.add(data);
    }, onDone: () => controller.close());
    return BootTestWebSocket._(
      incoming: controller.stream,
      send: (msg) => ws.add(msg),
      close: ([code = 1000]) async => ws.close(code),
    );
  }

  /// Create from a simulated channel (unit test mode).
  factory BootTestWebSocket.simulated(_FakeWebSocket serverSocket) {
    return BootTestWebSocket._(
      incoming: serverSocket.sentToClient.stream,
      send: (msg) => serverSocket.receiveFromClient(msg),
      close: ([code = 1000]) async => serverSocket.simulateClose(code),
    );
  }

  /// Send a message to the server.
  void send(String message) => _sendFn(message);

  /// Await the next message from the server.
  Future<String> get next => _messages.stream.first;

  /// Stream of all messages from the server.
  Stream<String> get messages => _messages.stream;

  /// All messages received so far.
  List<String> get received => List.unmodifiable(_received);

  /// Whether the connection is closed.
  bool get isClosed => _closed;

  /// Close the connection.
  Future<void> close([int code = 1000]) async {
    await _closeFn(code);
    await _sub.cancel();
    await _messages.close();
    _closed = true;
  }
}

/// Simulates a WebSocket connection for unit testing.
/// Connects a BootTestWebSocket (client side) to a WebSocketSession (server side).
BootTestWebSocket simulateWebSocketConnection(
  WebSocketServer server,
  String path, {
  dynamic authentication,
}) {
  final match = server.matchEndpoint(path);
  if (match == null) {
    throw StateError('No WebSocket endpoint registered for path: $path');
  }

  final fakeSocket = _FakeWebSocket(pathParams: match.pathParams);

  // Create a real WebSocketSession backed by the fake socket
  final session = WebSocketSession(
    fakeSocket,
    id: 'test-${DateTime.now().microsecondsSinceEpoch}',
    pathParams: match.pathParams,
    authentication: authentication,
  );

  // Register session for broadcast support
  server.addSession(path, session);

  // Create the client-side test websocket
  final testWs = BootTestWebSocket.simulated(fakeSocket);

  // Invoke the handler (triggers onOpen, sets up onMessage, etc.)
  match.handler(session);

  return testWs;
}

/// A fake WebSocket that works in-memory for testing.
/// Implements dart:io WebSocket just enough for WebSocketSession to work.
class _FakeWebSocket extends Stream<dynamic> implements WebSocket {
  final Map<String, String> pathParams;
  final sentToClient = StreamController<String>.broadcast(sync: true);
  final _incomingController = StreamController<dynamic>.broadcast(sync: true);
  final _doneCompleter = Completer<void>();
  int? _closeCode;
  String? _closeReason;

  _FakeWebSocket({this.pathParams = const {}});

  /// Simulate receiving a message from the client.
  void receiveFromClient(String message) {
    _incomingController.add(message);
  }

  /// Simulate the client closing the connection.
  void simulateClose(int code) {
    _closeCode = code;
    _incomingController.close();
    sentToClient.close();
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  // --- Stream implementation (WebSocket extends Stream<dynamic>) ---

  @override
  StreamSubscription<dynamic> listen(void Function(dynamic event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _incomingController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // --- WebSocket interface (server sends to client) ---

  @override
  void add(dynamic data) {
    if (!sentToClient.isClosed && data is String) sentToClient.add(data);
  }

  @override
  Future close([int? code, String? reason]) async {
    _closeCode = code;
    _closeReason = reason;
    simulateClose(code ?? 1000);
  }

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  Future get done => _doneCompleter.future;
  @override
  String? get protocol => null;
  @override
  int get readyState => _closeCode != null ? WebSocket.closed : WebSocket.open;
  @override
  String get extensions => '';
  @override
  set pingInterval(Duration? interval) {}
  @override
  Duration? get pingInterval => null;
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream stream) async {}
  @override
  void addUtf8Text(List<int> bytes) {}
}
