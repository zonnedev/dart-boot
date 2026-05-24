// coverage:ignore-file
import 'websocket_server.dart';

/// Builder for creating configured [WebSocketServer] instances.
class WebSocketServerBuilder {
  int _maxFrameSize;
  Duration? _pingInterval;

  WebSocketServerBuilder({
    int maxFrameSize = 65536,
    Duration? pingInterval,
  })  : _maxFrameSize = maxFrameSize,
        _pingInterval = pingInterval;

  WebSocketServerBuilder maxFrameSize(int size) {
    _maxFrameSize = size;
    return this;
  }

  WebSocketServerBuilder pingInterval(Duration d) {
    _pingInterval = d;
    return this;
  }

  WebSocketServer build() => WebSocketServer(
        maxFrameSize: _maxFrameSize,
        pingInterval: _pingInterval,
      );
}
