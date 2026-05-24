import 'package:boot_events/boot_events.dart';
import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

class UserCreated {
  final String name;
  UserCreated(this.name);
}

class UserDeleted {
  final String id;
  UserDeleted(this.id);
}

void main() {
  late EventBus bus;

  setUp(() => bus = EventBus());

  group('EventBus.on and publish', () {
    test('listener receives published event', () {
      final events = <UserCreated>[];
      bus.on<UserCreated>((e) => events.add(e));
      bus.publish(UserCreated('Alice'));
      expect(events.length, 1);
      expect(events.first.name, 'Alice');
    });

    test('multiple listeners all receive the event', () {
      var count = 0;
      bus.on<UserCreated>((_) => count++);
      bus.on<UserCreated>((_) => count++);
      bus.on<UserCreated>((_) => count++);
      bus.publish(UserCreated('Bob'));
      expect(count, 3);
    });

    test('listeners only receive their type', () {
      final created = <UserCreated>[];
      final deleted = <UserDeleted>[];
      bus.on<UserCreated>((e) => created.add(e));
      bus.on<UserDeleted>((e) => deleted.add(e));

      bus.publish(UserCreated('X'));
      bus.publish(UserDeleted('1'));

      expect(created.length, 1);
      expect(deleted.length, 1);
    });

    test('publish with no listeners does not throw', () {
      bus.publish(UserCreated('nobody listening'));
    });

    test('listener added during publish does not cause error', () {
      bus.on<UserCreated>((e) {
        // Add another listener during iteration
        bus.on<UserCreated>((_) {});
      });
      bus.publish(UserCreated('concurrent'));
      // No ConcurrentModificationException
    });
  });

  group('EventBus.onType', () {
    test('registers by runtime Type', () {
      final events = <dynamic>[];
      bus.onType(UserCreated, (e) => events.add(e));
      bus.publish(UserCreated('typed'));
      expect(events.length, 1);
    });
  });

  group('EventBus.publishAsync', () {
    test('waits for async listeners', () async {
      var completed = false;
      bus.on<UserCreated>((e) async {
        await Future.delayed(Duration(milliseconds: 10));
        completed = true;
      });
      await bus.publishAsync(UserCreated('async'));
      expect(completed, isTrue);
    });

    test('waits for multiple async listeners in order', () async {
      final order = <int>[];
      bus.on<UserCreated>((e) async {
        await Future.delayed(Duration(milliseconds: 20));
        order.add(1);
      });
      bus.on<UserCreated>((e) async {
        await Future.delayed(Duration(milliseconds: 10));
        order.add(2);
      });
      await bus.publishAsync(UserCreated('order'));
      expect(order, [1, 2]); // sequential, not parallel
    });

    test('handles mix of sync and async listeners', () async {
      final order = <String>[];
      bus.on<UserCreated>((e) => order.add('sync'));
      bus.on<UserCreated>((e) async {
        await Future.delayed(Duration(milliseconds: 5));
        order.add('async');
      });
      await bus.publishAsync(UserCreated('mix'));
      expect(order, ['sync', 'async']);
    });

    test('publishAsync with no listeners does not throw', () async {
      await bus.publishAsync(UserCreated('nobody'));
    });
  });

  group('EventBus with DI container', () {
    test('EventBus as singleton in container', () {
      final container = BeanContainer();
      final bus = EventBus();
      container.overrideWithInstance<EventBus>(bus);

      final resolved = container.get<EventBus>();
      expect(identical(resolved, bus), isTrue);
    });

    test('services publish events via injected EventBus', () {
      final container = BeanContainer();
      final bus = EventBus();
      container.overrideWithInstance<EventBus>(bus);

      final events = <UserCreated>[];
      bus.on<UserCreated>((e) => events.add(e));

      // Simulate a service using the container's EventBus
      final injectedBus = container.get<EventBus>();
      injectedBus.publish(UserCreated('from-service'));

      expect(events.length, 1);
      expect(events.first.name, 'from-service');
    });

    test('multiple services share same EventBus instance', () {
      final container = BeanContainer();
      final bus = EventBus();
      container.overrideWithInstance<EventBus>(bus);

      final bus1 = container.get<EventBus>();
      final bus2 = container.get<EventBus>();
      expect(identical(bus1, bus2), isTrue);

      // Listener on bus1 receives publish from bus2
      final events = <UserCreated>[];
      bus1.on<UserCreated>((e) => events.add(e));
      bus2.publish(UserCreated('shared'));
      expect(events.length, 1);
    });

    test('simulates generated @EventListener wiring', () {
      final container = BeanContainer();
      final bus = EventBus();
      container.overrideWithInstance<EventBus>(bus);

      // Simulate what $configure generates:
      // container.get<EventBus>().on<UserCreated>((event) => listener.onUserCreated(event));
      final handled = <String>[];
      container.get<EventBus>().on<UserCreated>((e) => handled.add(e.name));
      container.get<EventBus>().on<UserDeleted>((e) => handled.add('del:${e.id}'));

      // Simulate controller publishing
      bus.publish(UserCreated('Alice'));
      bus.publish(UserDeleted('42'));

      expect(handled, ['Alice', 'del:42']);
    });

    test('override EventBus in test isolates events', () {
      final prodBus = EventBus();
      final testBus = EventBus();

      final container = BeanContainer();
      container.overrideWithInstance<EventBus>(prodBus);
      // Test overrides with a fresh bus
      container.overrideWithInstance<EventBus>(testBus);

      final events = <UserCreated>[];
      container.get<EventBus>().on<UserCreated>((e) => events.add(e));

      // Publish on prod bus — should NOT reach test listener
      prodBus.publish(UserCreated('prod'));
      expect(events, isEmpty);

      // Publish on test bus — should reach
      testBus.publish(UserCreated('test'));
      expect(events.length, 1);
    });
  });

  group('Built-in events', () {
    test('StartupEvent stores uri', () {
      final e = StartupEvent(Uri.parse('http://localhost:8080'));
      expect(e.uri.port, 8080);
    });

    test('ShutdownEvent is const', () {
      const e = ShutdownEvent();
      expect(e, isNotNull);
    });
  });
}
