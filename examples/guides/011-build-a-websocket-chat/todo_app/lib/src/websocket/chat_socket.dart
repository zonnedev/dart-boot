import 'package:boot/boot.dart';

part 'chat_socket.g.dart';

@ServerWebSocket('/chat/<room>')
class ChatSocket {
  final WebSocketServer _server;
  ChatSocket(this._server);

  @OnOpen()
  void onOpen(WebSocketSession session, String room) {
    _server.broadcast('/chat/$room', '📢 A new user joined the room');
    session.send('Welcome to room "$room"!');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message, String room) {
    _server.broadcast('/chat/$room', message);
  }

  @OnClose()
  void onClose(WebSocketSession session, String room) {
    _server.broadcast('/chat/$room', '📢 A user left the room');
  }

  @OnError()
  void onError(WebSocketSession session, Object error, String room) {
    print('❌ Error for ${session.id} in $room: $error');
  }
}
