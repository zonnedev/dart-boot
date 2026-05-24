# Guide 012: WebSocket with Auth

## What you'll build

Add authentication to the chat WebSocket — reject unauthorized connections before the upgrade, and identify users in messages.

## What you'll learn

- How WebSocket authentication works (token in query param or header)
- How Boot validates credentials before upgrading the connection
- How to access the authenticated user in WebSocket handlers
- How mTLS works for device-to-server WebSockets (IoT/OCPP)
- How to test authenticated WebSocket endpoints

## Prerequisites

- Completed [Guide 003](003-add-authentication.md) (JWT auth provider)
- Completed [Guide 011](011-build-a-websocket-chat.md) (WebSocket basics)

---

## Step 1: The problem

Without auth, anyone can connect to your WebSocket. For a chat app, you want to know WHO is connected. For IoT devices, you need to verify the device is legitimate.

The challenge: browsers' `WebSocket` API doesn't support custom headers. You can't send `Authorization: Bearer token` like with HTTP requests. The standard solutions:

1. **Token in query parameter** — `ws://host/chat?token=eyJ...` (works everywhere)
2. **Token in header** — works for non-browser clients (mobile apps, servers)
3. **Client certificate (mTLS)** — works for IoT devices with certificates

Boot supports all three through the same `AuthenticationProvider` you already wrote for HTTP.

---

## Step 2: Enable WebSocket auth

**`application.yml`**:

```yaml
boot:
  websocket:
    enabled: true
    auth: true    # ← this is the only change needed
```

That's it. Boot now calls your `AuthenticationProvider` beans before upgrading any WebSocket connection. If auth fails → 401, connection rejected.

---

## Step 3: How it works

When a client connects to `ws://localhost:8080/chat/general?token=eyJ...`:

1. Boot receives the HTTP upgrade request
2. Extracts the token from `?token=` query param (or `Authorization` header)
3. Calls your `JwtAuthProvider.authenticate()` (same one from Guide 003)
4. If it returns `Authentication` → upgrade proceeds, `session.authentication` is set
5. If it returns `null` → 401 response, connection never opens

The client never gets a WebSocket connection if auth fails.

---

## Step 4: Use authentication in handlers

Update the chat socket to show usernames:

**`lib/src/websocket/chat_socket.dart`**

```dart
import 'package:boot/boot.dart';

part 'chat_socket.g.dart';

@ServerWebSocket('/chat/<room>')
class ChatSocket {
  final WebSocketServer _server;
  ChatSocket(this._server);

  @OnOpen()
  void onOpen(WebSocketSession session, String room) {
    final user = session.authentication;  // guaranteed non-null when auth: true
    print('👤 ${user.name} joined room: $room');
    _server.broadcast('/chat/$room', '📢 ${user.name} joined');
    session.send('Welcome, ${user.name}! You are in room "$room".');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message, String room) {
    final user = session.authentication;
    // Broadcast with username prefix
    _server.broadcast('/chat/$room', '${user.name}: $message');
  }

  @OnClose()
  void onClose(WebSocketSession session, String room) {
    final user = session.authentication;
    _server.broadcast('/chat/$room', '📢 ${user.name} left');
  }
}
```

**What's happening:**

- `session.authentication` — the `Authentication` object from your provider. Contains `name` and `roles`.
- When `boot.websocket.auth: true`, this is guaranteed non-null (unauthenticated connections are rejected before `@OnOpen` runs)
- You can use `user.roles` for authorization (e.g., only admins can broadcast to all rooms)

---

## Step 5: Test manually

**Get a token first:**

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}' | jq -r '.token')

echo $TOKEN
```

**Connect with the token:**

```bash
websocat "ws://localhost:8080/chat/general?token=$TOKEN"
```

Output:
```
Welcome, admin! You are in room "general".
```

**Try without a token:**

```bash
websocat ws://localhost:8080/chat/general
```

Output:
```
websocat: server returned 401
```

Connection rejected — never upgraded.

---

## Step 6: Browser client with auth

```javascript
// Get token from login
const loginRes = await fetch('/auth/login', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({username: 'alice', password: 'alice123'}),
});
const {token} = await loginRes.json();

// Connect WebSocket with token in URL
const ws = new WebSocket(`ws://localhost:8080/chat/general?token=${token}`);

ws.onopen = () => console.log('Connected!');
ws.onmessage = (e) => console.log(e.data);
ws.onclose = (e) => {
  if (e.code === 1008) console.log('Auth failed');
};
```

---

## Step 7: Role-based WebSocket access

Check roles in `@OnOpen` to restrict who can join:

```dart
@OnOpen()
void onOpen(WebSocketSession session, String room) {
  final user = session.authentication;

  // Only admins can join the "admin" room
  if (room == 'admin' && !user.roles.contains('ROLE_ADMIN')) {
    session.send('Error: You need ROLE_ADMIN to join this room');
    session.close(4003, 'Forbidden');
    return;
  }

  _server.broadcast('/chat/$room', '📢 ${user.name} joined');
}
```

---

## Step 8: mTLS for IoT devices

For devices that authenticate with client certificates (OCPP chargers, IoT sensors):

**`application.yml`**:

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

**`lib/src/security/device_auth_provider.dart`**:

```dart
import 'dart:io';
import 'package:boot/boot.dart';

part 'device_auth_provider.g.dart';

@Singleton()
class DeviceAuthProvider implements AuthenticationProvider {
  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    // Check for client certificate (mTLS)
    final certs = request.clientCertificates;
    if (certs == null || certs.isEmpty) return null;

    final cert = certs.first as X509Certificate;
    final cn = _extractCN(cert.subject);

    // Verify the device is known (check database, allowlist, etc.)
    return Authentication(name: cn, roles: ['device']);
  }

  String _extractCN(String subject) {
    final match = RegExp(r'CN=([^,]+)').firstMatch(subject);
    return match?.group(1) ?? subject;
  }
}
```

Now devices connect with their certificate — no token needed:

```bash
# Device connects with its client cert
websocat --tls-cert device.pem --tls-key device-key.pem \
  wss://server:8080/devices/charger-001
```

The same `AuthenticationProvider` interface handles both JWT tokens (for web users) and mTLS certificates (for devices). Boot tries all providers in order.

---

## Step 9: Write tests

**`test/websocket_auth_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/websocket/chat_socket.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket Auth', () {
    test('WebSocket server requires auth when configured', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.authRequired, isTrue);
      });
    });

    test('WebSocket server does not require auth by default', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        // auth not set → defaults to false
      }, test: (client, container) async {
        final server = container.get<WebSocketServer>();
        expect(server.authRequired, isFalse);
      });
    });

    test('auth providers are wired to WebSocket server', () async {
      await bootTest($configure, properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      }, test: (client, container) async {
        // The JwtAuthProvider should be available for WebSocket auth
        final providers = container.getAll<AuthenticationProvider>();
        expect(providers, isNotEmpty);
      });
    });
  });
}
```

---

## Summary: Auth methods for WebSocket

| Method | How client connects | Use case |
|---|---|---|
| Token in URL | `ws://host/path?token=eyJ...` | Browser clients |
| Token in header | `Authorization: Bearer eyJ...` | Mobile apps, servers |
| Client certificate | TLS with client cert | IoT devices, OCPP |

All three use the same `AuthenticationProvider` — no separate WebSocket auth code needed.

---

## What you've learned

- `boot.websocket.auth: true` enables auth on WebSocket upgrade
- Boot reuses the same `AuthenticationProvider` beans from HTTP
- Tokens can be in `?token=` query param or `Authorization` header
- `session.authentication` gives you the user in all handlers
- Unauthenticated connections get 401 before the upgrade
- mTLS works for device authentication (same provider interface)
- Role checks can be done in `@OnOpen`

## Next steps

- [Guide 013: Schedule Background Tasks](013-schedule-background-tasks.md) — run periodic jobs
