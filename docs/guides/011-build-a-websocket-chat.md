# Guide 011: Build a WebSocket Chat

## What you'll build

A real-time chat room where multiple users can send and receive messages instantly.

## What you'll learn

- How to create a WebSocket endpoint with `@ServerWebSocket`
- How to handle connections, messages, and disconnections
- How to broadcast messages to all connected clients
- How to use path parameters for chat rooms
- How to test WebSocket beans

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: What are WebSockets?

WebSockets provide a persistent, two-way connection between client and server. Unlike HTTP (request → response → done), a WebSocket stays open and both sides can send messages at any time.

```
HTTP:       Client --request--> Server --response--> done
WebSocket:  Client <---messages---> Server (stays open)
```

Use WebSockets for: chat, multiplayer games, collaborative editing, live dashboards.

---

## Step 2: Enable WebSockets

**`application.yml`** — add:

```yaml
boot:
  websocket:
    enabled: true
```

---

## Step 3: Create the chat endpoint

**`lib/src/websocket/chat_socket.dart`**

```dart
import 'package:boot/boot.dart';

part 'chat_socket.g.dart';

/// A chat room WebSocket endpoint.
/// Connect to: ws://localhost:8080/chat/<room>
@ServerWebSocket('/chat/<room>')
class ChatSocket {
  final WebSocketServer _server;
  ChatSocket(this._server);

  /// Called when a new client connects.
  @OnOpen()
  void onOpen(WebSocketSession session, String room) {
    print('👤 User ${session.id} joined room: $room');
    // Notify others in the room
    _server.broadcast('/chat/$room', '📢 A new user joined the room');
    // Welcome the new user
    session.send('Welcome to room "$room"! There are ${_roomSize(room)} users here.');
  }

  /// Called when a client sends a message.
  @OnMessage()
  void onMessage(WebSocketSession session, String message, String room) {
    print('💬 [${session.id}] in $room: $message');
    // Broadcast to everyone in the room (including sender)
    _server.broadcast('/chat/$room', message);
  }

  /// Called when a client disconnects.
  @OnClose()
  void onClose(WebSocketSession session, String room) {
    print('👋 User ${session.id} left room: $room');
    _server.broadcast('/chat/$room', '📢 A user left the room');
  }

  /// Called when an error occurs on the connection.
  @OnError()
  void onError(WebSocketSession session, Object error, String room) {
    print('❌ Error for ${session.id} in $room: $error');
  }

  int _roomSize(String room) {
    // Access connected sessions for this path
    return 0; // simplified
  }
}
```

**What's happening:**

- `@ServerWebSocket('/chat/<room>')` — defines a WebSocket endpoint with a path parameter
- `<room>` — extracted from the URL, passed to each handler method
- `@OnOpen()` — called when a client connects
- `@OnMessage()` — called when a client sends a message
- `@OnClose()` — called when a client disconnects
- `@OnError()` — called when something goes wrong
- `_server.broadcast(path, message)` — sends a message to ALL clients connected to that path
- `session.send(message)` — sends a message to ONE specific client

---

## Step 4: The WebSocketSession API

```dart
session.id;                    // Unique connection ID
session.send('text');          // Send a text message to this client
session.sendBytes(bytes);      // Send binary data
session.close(1000, 'bye');    // Close the connection
session.headers;               // HTTP headers from the upgrade request
session.pathParams;            // URL path parameters {'room': 'general'}
session.subprotocol;           // Negotiated subprotocol (if any)
session.authentication;        // Authenticated user (if auth enabled)
session.attributes;            // Custom key-value storage per session
```

---

## Step 5: Export and build

**`lib/todo_app.dart`** — add export:

```dart
export 'src/websocket/chat_socket.dart';
```

```bash
boot build
boot serve
```

---

## Step 6: Test manually

You need a WebSocket client. The easiest is `websocat` (install: `cargo install websocat` or `brew install websocat`):

**Terminal 1 — User A joins "general" room:**

```bash
websocat ws://localhost:8080/chat/general
```

Output:
```
Welcome to room "general"! There are 0 users here.
```

**Terminal 2 — User B joins the same room:**

```bash
websocat ws://localhost:8080/chat/general
```

Terminal 1 sees:
```
📢 A new user joined the room
```

**User A types a message (in Terminal 1):**

```
Hello everyone!
```

Both terminals see:
```
Hello everyone!
```

**User B disconnects (Ctrl+C in Terminal 2):**

Terminal 1 sees:
```
📢 A user left the room
```

---

## Step 7: Multiple rooms

Because the path has `<room>`, different URLs create different rooms:

```bash
websocat ws://localhost:8080/chat/general    # Room: general
websocat ws://localhost:8080/chat/random     # Room: random
websocat ws://localhost:8080/chat/dev-team   # Room: dev-team
```

Messages in one room don't appear in others — `broadcast('/chat/general', ...)` only reaches clients connected to `/chat/general`.

---

## Step 8: Store per-session data

Use `session.attributes` to store data about each connection:

```dart
@OnOpen()
void onOpen(WebSocketSession session, String room) {
  session.attributes['joinedAt'] = DateTime.now();
  session.attributes['nickname'] = 'User-${session.id.substring(0, 4)}';
  session.send('Your nickname is: ${session.attributes['nickname']}');
}

@OnMessage()
void onMessage(WebSocketSession session, String message, String room) {
  final nickname = session.attributes['nickname'];
  _server.broadcast('/chat/$room', '$nickname: $message');
}
```

---

## Step 9: Browser client

```html
<!DOCTYPE html>
<html>
<body>
  <input id="msg" placeholder="Type a message..." />
  <button onclick="send()">Send</button>
  <div id="messages"></div>

  <script>
    const room = 'general';
    const ws = new WebSocket(`ws://localhost:8080/chat/${room}`);

    ws.onmessage = (event) => {
      const div = document.createElement('div');
      div.textContent = event.data;
      document.getElementById('messages').prepend(div);
    };

    ws.onclose = () => {
      const div = document.createElement('div');
      div.textContent = '--- Disconnected ---';
      document.getElementById('messages').prepend(div);
    };

    function send() {
      const input = document.getElementById('msg');
      ws.send(input.value);
      input.value = '';
    }
  </script>
</body>
</html>
```

Save as `public/chat.html` and access at `http://localhost:8080/static/chat.html` (if static serving is enabled).

---

## Step 10: Write automated tests

**`test/chat_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/websocket/chat_socket.dart';
import 'package:test/test.dart';

void main() {
  group('ChatSocket', () {
    test('ChatSocket bean is registered', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final chat = container.get<ChatSocket>();
        expect(chat, isNotNull);
      });
    });

    test('WebSocketServer is available when enabled', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server, isNotNull);
      });
    });
  });
}
```

For full integration tests with actual WebSocket connections, use `dart:io`'s `WebSocket.connect()` against a running server:

```dart
import 'dart:io';

test('full WebSocket integration', () async {
  // Start the server on a random port
  // Connect with WebSocket.connect('ws://localhost:$port/chat/test')
  // Send messages and verify they're received
  // This requires a running server — better suited for integration test suite
});
```

---

## Step 11: WebSocket with authentication

See [Guide 012](012-websocket-with-auth.md) for adding token validation on the WebSocket upgrade.

---

## What you've learned

- `@ServerWebSocket('/path/<param>')` creates a WebSocket endpoint
- `@OnOpen`, `@OnMessage`, `@OnClose`, `@OnError` handle lifecycle events
- `session.send()` sends to one client
- `_server.broadcast(path, message)` sends to all clients on a path
- Path parameters create separate rooms/channels
- `session.attributes` stores per-connection data
- WebSockets are two-way — both client and server can send at any time
- Enable with `boot.websocket.enabled: true`

## Next steps

- [Guide 012: WebSocket with Auth](012-websocket-with-auth.md) — require tokens or certificates on upgrade
