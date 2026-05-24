# boot_events

Event system for the Boot Framework.

## Features

- `EventBus` — publish/subscribe with type-safe events
- `@EventListener` — annotation for auto-discovered listeners
- `StartupEvent`, `ShutdownEvent` — built-in lifecycle events

## Usage

```dart
class UserCreated { final String name; UserCreated(this.name); }

// Publish
eventBus.publish(UserCreated('Alice'));

// Listen
eventBus.on<UserCreated>((e) => print('Created: ${e.name}'));
```
