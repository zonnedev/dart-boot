# Guide 010: Server-Sent Events

## What you'll build

A real-time notification feed that pushes updates to connected browsers without them having to refresh or poll.

## What you'll learn

- What Server-Sent Events (SSE) are and when to use them
- How to return a `Stream<SseEvent>` from a controller
- How to push events from other parts of your app
- The difference between SSE and WebSockets
- How to test streaming endpoints

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: What are Server-Sent Events?

SSE is a simple way for the server to push data to the browser over a long-lived HTTP connection. Unlike WebSockets, SSE is:

- **One-directional** — server pushes to client (client can't send back over the same connection)
- **Built on HTTP** — works through proxies, load balancers, firewalls
- **Auto-reconnects** — the browser reconnects automatically if the connection drops
- **Simple** — no special protocol, just a text stream

Use SSE when you need to push updates (notifications, live scores, stock prices, logs). Use WebSockets when you need two-way communication (chat, games).

---

## Step 2: Create a simple SSE endpoint

A controller method that returns `Stream<SseEvent>` automatically becomes an SSE endpoint:

**`lib/src/controllers/events_controller.dart`**

```dart
import 'dart:async';
import 'package:boot/boot.dart';

part 'events_controller.g.dart';

@Controller('/events')
class EventsController {
  /// GET /events/time — pushes the current time every second.
  /// The connection stays open and the server keeps sending.
  @Get('/time')
  Stream<SseEvent> time(Request request) async* {
    while (true) {
      yield SseEvent(data: DateTime.now().toIso8601String());
      await Future.delayed(Duration(seconds: 1));
    }
  }
}
```

**What's happening:**

- `Stream<SseEvent>` return type — Boot detects this and sets up SSE automatically
- `async*` — makes this a generator function that produces values over time
- `yield` — sends one event to the client
- The `while (true)` loop keeps the connection open, sending every second
- When the client disconnects, the stream is cancelled automatically

---

## Step 3: The SseEvent class

```dart
SseEvent(
  data: 'Hello',          // required — the message content
  event: 'notification',  // optional — event type (client can filter by this)
  id: '42',              // optional — event ID (for reconnection)
  retry: 5000,           // optional — reconnect delay in ms (tells browser)
)
```

The wire format sent to the browser:
```
event: notification
id: 42
retry: 5000
data: Hello

```

---

## Step 4: Create a notification feed

A more realistic example — push notifications when things happen in the app:

**`lib/src/services/notification_stream.dart`**

```dart
import 'dart:async';
import 'package:boot/boot.dart';

part 'notification_stream.g.dart';

/// A shared stream that any part of the app can push notifications to.
/// All connected SSE clients receive them.
@Singleton()
class NotificationStream {
  final _controller = StreamController<String>.broadcast();

  /// Push a notification to all connected clients.
  void notify(String message) => _controller.add(message);

  /// The stream that SSE endpoints listen to.
  Stream<String> get stream => _controller.stream;
}
```

**`lib/src/controllers/events_controller.dart`** — updated:

```dart
import 'dart:async';
import 'package:boot/boot.dart';
import '../services/notification_stream.dart';

part 'events_controller.g.dart';

@Controller('/events')
class EventsController {
  final NotificationStream _notifications;
  EventsController(this._notifications);

  /// GET /events/time — pushes the current time every second.
  @Get('/time')
  Stream<SseEvent> time(Request request) async* {
    while (true) {
      yield SseEvent(data: DateTime.now().toIso8601String());
      await Future.delayed(Duration(seconds: 1));
    }
  }

  /// GET /events/notifications — real-time notification feed.
  /// Stays open and pushes whenever something happens in the app.
  @Get('/notifications')
  Stream<SseEvent> notifications(Request request) async* {
    var id = 0;
    await for (final message in _notifications.stream) {
      id++;
      yield SseEvent(
        data: message,
        event: 'notification',
        id: '$id',
      );
    }
  }
}
```

---

## Step 5: Push events from other controllers

When a todo is created, push a notification:

**`lib/src/controllers/todo_controller.dart`** — add notification:

```dart
@Controller('/todos')
class TodoController {
  final TodoRepository _repo;
  final NotificationStream _notifications;

  TodoController(this._repo, this._notifications);

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final title = body['title'] as String?;
    if (title == null || title.isEmpty) throw BadRequestException('Title is required');

    final todo = await _repo.create(title);

    // Push notification to all connected SSE clients
    _notifications.notify('New todo created: ${todo.title}');

    return Response.created(todo.toJson());
  }
}
```

---

## Step 6: Export and build

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/services/notification_stream.dart';
export 'src/controllers/events_controller.dart';
```

```bash
boot build
boot serve
```

---

## Step 7: Test manually

**Connect to the time stream:**

```bash
curl -N http://localhost:8080/events/time
```

Output (keeps streaming):
```
data: 2026-05-24T00:50:00.000Z

data: 2026-05-24T00:50:01.000Z

data: 2026-05-24T00:50:02.000Z
```

Press Ctrl+C to disconnect.

**Connect to notifications in one terminal:**

```bash
curl -N http://localhost:8080/events/notifications
```

**Create a todo in another terminal:**

```bash
curl -X POST http://localhost:8080/todos/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Buy milk"}'
```

The first terminal shows:
```
event: notification
id: 1
data: New todo created: Buy milk

```

---

## Step 8: Browser client

In your frontend JavaScript:

```javascript
const events = new EventSource('/events/notifications');

events.addEventListener('notification', (e) => {
  console.log('New notification:', e.data);
  // Update the UI
  const div = document.createElement('div');
  div.textContent = e.data;
  document.getElementById('notifications').prepend(div);
});

events.onerror = () => {
  console.log('Connection lost, reconnecting...');
  // EventSource reconnects automatically
};
```

---

## Step 9: Write automated tests

**`test/sse_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/notification_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Server-Sent Events', () {
    test('NotificationStream delivers messages', () async {
      await bootTest($configure, test: (client, container) async {
        final stream = container.get<NotificationStream>();
        final received = <String>[];

        // Listen
        final sub = stream.stream.listen((msg) => received.add(msg));

        // Push
        stream.notify('Hello');
        stream.notify('World');

        // Give async a moment
        await Future.delayed(Duration(milliseconds: 10));

        expect(received, ['Hello', 'World']);
        await sub.cancel();
      });
    });

    test('creating a todo pushes notification', () async {
      await bootTest($configure, test: (client, container) async {
        final stream = container.get<NotificationStream>();
        final received = <String>[];
        final sub = stream.stream.listen((msg) => received.add(msg));

        await client.post('/todos/', body: {'title': 'Test SSE'});

        await Future.delayed(Duration(milliseconds: 10));
        expect(received.length, 1);
        expect(received.first, contains('Test SSE'));
        await sub.cancel();
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 10: SSE vs WebSocket — when to use which

| Feature | SSE | WebSocket |
|---|---|---|
| Direction | Server → Client only | Both directions |
| Protocol | HTTP | Custom (ws://) |
| Reconnection | Automatic (built into browser) | Manual |
| Binary data | No (text only) | Yes |
| Proxy/firewall friendly | Yes | Sometimes blocked |
| Use for | Notifications, feeds, logs | Chat, games, collaboration |

**Rule of thumb:** If the client only needs to receive updates, use SSE. If the client needs to send messages too, use WebSocket.

---

## What you've learned

- `Stream<SseEvent>` return type creates an SSE endpoint automatically
- `async*` + `yield` produces events over time
- `SseEvent` has `data`, `event`, `id`, and `retry` fields
- Use a shared `StreamController.broadcast()` to push from anywhere in the app
- Browsers use `EventSource` API to connect and auto-reconnect
- Test by subscribing to the stream directly (no HTTP needed for unit tests)

## Next steps

- [Guide 011: Build a WebSocket Chat](011-build-a-websocket-chat.md) — two-way real-time communication
