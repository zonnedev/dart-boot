import 'package:boot/boot.dart';

part 'chat_socket.g.dart';

@ServerWebSocket('/chat/<room>')
class ChatSocket {
  final WebSocketServer _server;
  ChatSocket(this._server);

  @OnOpen()
  void onOpen(WebSocketSession session, String room) {
    final user = session.authentication;
    _server.broadcast('/chat/$room', '📢 ${user.name} joined');
    session.send('Welcome, ${user.name}! You are in room "$room".');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message, String room) {
    final user = session.authentication;
    _server.broadcast('/chat/$room', '${user.name}: $message');
  }

  @OnClose()
  void onClose(WebSocketSession session, String room) {
    final user = session.authentication;
    _server.broadcast('/chat/$room', '📢 ${user.name} left');
  }
}
