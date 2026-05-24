import 'package:boot/boot.dart';

part 'device_socket.g.dart';

@ServerWebSocket('/devices/<deviceId>')
class DeviceSocket {
  static final _log = Logger('DeviceSocket');

  @OnOpen()
  void onOpen(WebSocketSession session, String deviceId) {
    final auth = session.authentication;
    _log.info('Device connected', {'deviceId': deviceId, 'certCN': auth.name});
    session.send('{"status": "connected", "device": "$deviceId"}');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message, String deviceId) {
    _log.info('Message from $deviceId: $message');
    session.send('{"ack": true}');
  }

  @OnClose()
  void onClose(WebSocketSession session, String deviceId) {
    _log.info('Device disconnected: $deviceId');
  }
}
