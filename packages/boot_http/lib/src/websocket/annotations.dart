/// Marks a class as a WebSocket endpoint handler.
/// Implies @Singleton.
class ServerWebSocket {
  final String path;
  final List<String> protocols;
  final String? idleTimeout;
  final int? maxMessageSize;

  const ServerWebSocket(this.path, {this.protocols = const [], this.idleTimeout, this.maxMessageSize});
}

/// Method called when a new WebSocket connection is opened.
class OnOpen {
  const OnOpen();
}

/// Method called when a message is received.
class OnMessage {
  const OnMessage();
}

/// Method called when the connection is closed.
class OnClose {
  const OnClose();
}

/// Method called when an error occurs.
class OnError {
  const OnError();
}
