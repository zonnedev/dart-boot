# Guide 014: Publish and Subscribe Events

## What you'll build

A decoupled system where creating a todo triggers multiple side effects (send email, update analytics, notify WebSocket clients) — without the controller knowing about any of them.

## What you'll learn

- How to define custom event classes
- How to publish events with `EventBus`
- How to listen with `@EventListener`
- Why events decouple your code
- How to test event-driven behavior

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: The problem events solve

Without events, your controller does everything:

```dart
@Post('/')
Future<Response> create(Request request) async {
  final todo = await _repo.create(title);
  await _emailService.sendNotification(todo);     // tight coupling
  await _analyticsService.trackCreation(todo);    // more coupling
  await _notificationStream.notify(todo.title);   // even more
  return Response.created(todo.toJson());
}
```

Problems:
- Controller knows about email, analytics, notifications
- Adding a new side effect means editing the controller
- If email is slow, the whole request is slow
- Hard to test — need to mock everything

With events:

```dart
@Post('/')
Future<Response> create(Request request) async {
  final todo = await _repo.create(title);
  _eventBus.publish(TodoCreatedEvent(todo));  // fire and forget
  return Response.created(todo.toJson());
}
```

The controller publishes ONE event. Listeners handle the rest independently.

---

## Step 2: Define an event class

An event is just a plain Dart class — it carries data about what happened:

**`lib/src/events/todo_events.dart`**

```dart
import '../models/todo.dart';

/// Published when a new todo is created.
class TodoCreatedEvent {
  final Todo todo;
  final DateTime timestamp;

  TodoCreatedEvent(this.todo) : timestamp = DateTime.now();
}

/// Published when a todo is deleted.
class TodoDeletedEvent {
  final String todoId;
  final DateTime timestamp;

  TodoDeletedEvent(this.todoId) : timestamp = DateTime.now();
}

/// Published when a todo is completed.
class TodoCompletedEvent {
  final Todo todo;
  final DateTime timestamp;

  TodoCompletedEvent(this.todo) : timestamp = DateTime.now();
}
```

**What's happening:** Events are simple data holders. They describe what happened, not what should happen next. No logic, no dependencies.

---

## Step 3: Publish events from the controller

**`lib/src/controllers/todo_controller.dart`** — inject `EventBus` and publish:

```dart
import 'package:boot/boot.dart';
import '../models/todo.dart';
import '../events/todo_events.dart';
import '../repositories/todo_repository.dart';

part 'todo_controller.g.dart';

@Controller('/todos')
class TodoController {
  final TodoRepository _repo;
  final EventBus _eventBus;

  TodoController(this._repo, this._eventBus);

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final title = body['title'] as String?;
    if (title == null || title.isEmpty) throw BadRequestException('Title is required');

    final todo = await _repo.create(title);

    // Publish event — listeners handle the rest
    _eventBus.publish(TodoCreatedEvent(todo));

    return Response.created(todo.toJson());
  }

  @Delete('/<id>')
  Future<Response> delete(Request request, @PathParam() String id) async {
    final deleted = await _repo.delete(id);
    if (!deleted) throw NotFoundException('Todo $id not found');

    _eventBus.publish(TodoDeletedEvent(id));

    return Response.noContent();
  }
}
```

**What's happening:**

- `EventBus` is injected automatically (Boot provides it)
- `_eventBus.publish(event)` sends the event to all listeners
- The controller doesn't know or care who listens — it just announces what happened

---

## Step 4: Create event listeners

Listeners are methods annotated with `@EventListener` on any bean. Boot wires them automatically.

**`lib/src/listeners/email_listener.dart`**

```dart
import 'package:boot/boot.dart';
import '../events/todo_events.dart';

part 'email_listener.g.dart';

@Singleton()
class EmailListener {
  static final _log = Logger('EmailListener');

  /// Sends an email when a todo is created.
  /// Boot calls this automatically — you just declare the parameter type.
  @EventListener()
  void onTodoCreated(TodoCreatedEvent event) {
    _log.info('Sending email notification for: ${event.todo.title}');
    // In a real app: call email service
  }
}
```

**`lib/src/listeners/analytics_listener.dart`**

```dart
import 'package:boot/boot.dart';
import '../events/todo_events.dart';

part 'analytics_listener.g.dart';

@Singleton()
class AnalyticsListener {
  static final _log = Logger('AnalyticsListener');

  @EventListener()
  void onTodoCreated(TodoCreatedEvent event) {
    _log.info('Tracking: todo_created', {'title': event.todo.title});
  }

  @EventListener()
  void onTodoDeleted(TodoDeletedEvent event) {
    _log.info('Tracking: todo_deleted', {'id': event.todoId});
  }
}
```

**`lib/src/listeners/notification_listener.dart`**

```dart
import 'package:boot/boot.dart';
import '../events/todo_events.dart';
import '../services/notification_stream.dart';

part 'notification_listener.g.dart';

@Singleton()
class NotificationListener {
  final NotificationStream _notifications;
  NotificationListener(this._notifications);

  @EventListener()
  void onTodoCreated(TodoCreatedEvent event) {
    _notifications.notify('New todo: ${event.todo.title}');
  }

  @EventListener()
  void onTodoDeleted(TodoDeletedEvent event) {
    _notifications.notify('Todo deleted: ${event.todoId}');
  }
}
```

**What's happening:**

- `@EventListener()` — marks a method as an event listener
- The **parameter type** determines which events it receives (`TodoCreatedEvent`, `TodoDeletedEvent`)
- Multiple listeners can handle the same event — they all run
- Listeners are independent — they don't know about each other
- Adding a new listener doesn't require changing any existing code

---

## Step 5: How the flow works

```
User creates a todo
    ↓
TodoController publishes TodoCreatedEvent
    ↓
EventBus delivers to all listeners:
    → EmailListener.onTodoCreated()      — sends email
    → AnalyticsListener.onTodoCreated()  — tracks metric
    → NotificationListener.onTodoCreated() — pushes to SSE clients
```

Adding a new side effect (e.g., Slack notification) = add one new listener class. Nothing else changes.

---

## Step 6: Export and build

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/events/todo_events.dart';
export 'src/listeners/email_listener.dart';
export 'src/listeners/analytics_listener.dart';
export 'src/listeners/notification_listener.dart';
```

```bash
boot build
boot serve
```

**Test manually:**

```bash
curl -X POST http://localhost:8080/todos/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Test events"}'
```

Server output:
```
[INFO] EmailListener: Sending email notification for: Test events
[INFO] AnalyticsListener: Tracking: todo_created {title: Test events}
```

---

## Step 7: Write tests

**`test/events_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/events/todo_events.dart';
import 'package:todo_app/src/models/todo.dart';
import 'package:test/test.dart';

void main() {
  group('Events', () {
    test('creating a todo publishes TodoCreatedEvent', () async {
      await bootTest($configure, test: (client, container) async {
        final events = <TodoCreatedEvent>[];
        container.get<EventBus>().on<TodoCreatedEvent>((e) => events.add(e));

        await client.post('/todos/', body: {'title': 'Event test'});

        await Future.delayed(Duration(milliseconds: 10));
        expect(events.length, 1);
        expect(events.first.todo.title, 'Event test');
      });
    });

    test('deleting a todo publishes TodoDeletedEvent', () async {
      await bootTest($configure, test: (client, container) async {
        final events = <TodoDeletedEvent>[];
        container.get<EventBus>().on<TodoDeletedEvent>((e) => events.add(e));

        // Create then delete
        final createRes = await client.post('/todos/', body: {'title': 'Delete me'});
        final id = createRes.json()['id'];
        await client.delete('/todos/$id');

        await Future.delayed(Duration(milliseconds: 10));
        expect(events.length, 1);
        expect(events.first.todoId, id);
      });
    });

    test('multiple listeners receive the same event', () async {
      await bootTest($configure, test: (client, container) async {
        var count = 0;
        container.get<EventBus>().on<TodoCreatedEvent>((_) => count++);
        container.get<EventBus>().on<TodoCreatedEvent>((_) => count++);

        await client.post('/todos/', body: {'title': 'Multi listener'});

        await Future.delayed(Duration(milliseconds: 10));
        // 2 test subscribers + the registered @EventListener beans
        expect(count, 2);
      });
    });

    test('EventBus.publish works directly', () async {
      await bootTest($configure, test: (client, container) async {
        final events = <TodoCompletedEvent>[];
        container.get<EventBus>().on<TodoCompletedEvent>((e) => events.add(e));

        final todo = Todo(id: '1', title: 'Test', completed: true);
        container.get<EventBus>().publish(TodoCompletedEvent(todo));

        await Future.delayed(Duration(milliseconds: 10));
        expect(events.length, 1);
        expect(events.first.todo.completed, isTrue);
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 8: When to use events vs direct calls

| Use events when... | Use direct calls when... |
|---|---|
| Multiple things should happen | Only one thing should happen |
| Side effects are independent | Steps must happen in order |
| You want loose coupling | You need the result back |
| Adding new reactions shouldn't change existing code | The caller needs to know if it succeeded |

---

## What you've learned

- Events are plain Dart classes that describe what happened
- `EventBus.publish(event)` sends to all listeners
- `@EventListener()` on a method subscribes it (parameter type = event type)
- Multiple listeners can handle the same event independently
- Adding new listeners doesn't change existing code
- In tests, use `EventBus.on<T>()` directly to verify events are published
- Events decouple your code — the publisher doesn't know who listens

## Next steps

- [Guide 015: Create a Library](015-create-a-library.md) — package your code for others to use
