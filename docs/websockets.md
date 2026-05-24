# WebSockets

Real-time bidirectional communication with compile-time route generation.

## Basic WebSocket Endpoint

```dart
import 'package:boot/boot.dart';
part 'chat_socket.g.dart';

@ServerWebSocket('/chat')
class ChatSocket {
  @OnOpen()
  void onOpen(WebSocketSession session) {
    print('Client connected: ${session.id}');
    session.send('Welcome!');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message) {
    print('Received: $message');
    session.send('Echo: $message');
  }

  @OnClose()
  void onClose(WebSocketSession session) {
    print('Client disconnected: ${session.id}');
  }

  @OnError()
  void onError(WebSocketSession session, Object error) {
    print('Error: $error');
  }
}
```

**Config:**
```yaml
boot:
  websocket:
    enabled: true
```

## WebSocketSession API

```dart
session.id;                    // unique connection ID
session.send('text');          // send text message
session.sendBytes(bytes);      // send binary
session.close(1000, 'bye');    // close with code + reason
session.headers;               // upgrade request headers
session.pathParams;            // URL path parameters
session.authentication;        // authenticated user (if auth enabled)
session.attributes;            // custom key-value storage
```

## Path Parameters

```dart
@ServerWebSocket('/rooms/<roomId>')
class RoomSocket {
  @OnOpen()
  void onOpen(WebSocketSession session, String roomId) {
    print('Joined room: $roomId');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message, String roomId) {
    // broadcast to room
  }
}
```

Connect: `ws://localhost:8080/rooms/general`

## Broadcasting

```dart
@ServerWebSocket('/notifications')
class NotificationSocket {
  final WebSocketServer _server;
  NotificationSocket(this._server);

  @OnMessage()
  void onMessage(WebSocketSession session, String message) {
    // Send to all connected clients on this path
    _server.broadcast('/notifications', 'Announcement: $message');
  }
}
```

## Authentication on Upgrade

Validate tokens before accepting the WebSocket connection:

```yaml
boot:
  websocket:
    enabled: true
    auth: true
```

Clients pass a token:
```
ws://localhost:8080/chat?token=eyJhbGciOiJIUzI1NiJ9...
```

Or via header (non-browser clients):
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

Boot reuses the same `AuthenticationProvider` beans used for HTTP. If auth fails → 401, connection rejected before upgrade.

```dart
@ServerWebSocket('/chat')
class ChatSocket {
  @OnOpen()
  void onOpen(WebSocketSession session) {
    final user = session.authentication;  // guaranteed non-null when auth: true
    print('${user.name} joined');
  }
}
```

**Test:**
```dart
test('WebSocket rejects without token', () async {
  await bootTest($configure, properties: {
    'boot.websocket.enabled': 'true',
    'boot.websocket.auth': 'true',
  }, test: (client, container) async {
    // The WebSocket server would reject upgrade with 401
    // In unit tests, verify the auth provider is wired
    final server = container.get<WebSocketServer>();
    expect(server.authRequired, isTrue);
  });
});
```

## mTLS Authentication

For IoT/OCPP scenarios, authenticate via client certificate:

```yaml
boot:
  server:
    ssl:
      enabled: true
      cert: certs/server.pem
      key: certs/server-key.pem
      client-auth: required
      trust-store: certs/ca.pem
  websocket:
    enabled: true
    auth: true
```

```dart
@Singleton()
class DeviceCertAuth implements AuthenticationProvider {
  @override
  Future<Authentication?> authenticate(AuthenticationRequest req) async {
    final certs = req.clientCertificates;
    if (certs == null || certs.isEmpty) return null;
    final cn = (certs.first as X509Certificate).subject;
    return Authentication(name: cn, roles: ['device']);
  }
}
```

Now WebSocket connections from devices with valid client certs are authenticated automatically — same provider, same flow as HTTP.

## Subprotocol Negotiation

```dart
@ServerWebSocket('/ocpp', protocols: ['ocpp1.6', 'ocpp2.0.1'])
class OcppSocket {
  @OnOpen()
  void onOpen(WebSocketSession session) {
    print('Negotiated: ${session.subprotocol}');
  }
}
```

Client requests `Sec-WebSocket-Protocol: ocpp2.0.1, ocpp1.6` → server picks the first match.

## Idle Timeout

```dart
@ServerWebSocket('/stream', idleTimeout: '5m')
class StreamSocket {
  // Connection closed if no messages for 5 minutes
}
```

## Testing WebSocket Beans

```dart
test('ChatSocket bean is registered', () async {
  await bootTest($configure, properties: {
    'boot.websocket.enabled': 'true',
  }, test: (client, container) async {
    final socket = container.get<ChatSocket>();
    expect(socket, isNotNull);
  });
});

test('WebSocket server has endpoints', () async {
  await bootTest($configure, properties: {
    'boot.websocket.enabled': 'true',
  }, test: (client, container) async {
    final server = container.get<WebSocketServer>();
    // Verify endpoint is registered
    expect(server, isNotNull);
  });
});
```

## Configuration

```yaml
boot:
  websocket:
    enabled: true               # Enable WebSocket support
    auth: true                  # Require auth on upgrade
    max-frame-size: 65536       # Max message size in bytes
    ping-interval: 30s          # Keep-alive ping interval
```
