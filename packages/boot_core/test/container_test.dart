import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

// ─── Test helpers ────────────────────────────────────────────────────────────

abstract class Service {
  String get name;
}

class ServiceA implements Service {
  @override
  String get name => 'A';
}

class ServiceB implements Service {
  @override
  String get name => 'B';
}

class ServiceC implements Service {
  @override
  String get name => 'C';
}

class DependsOnService {
  final Service service;
  DependsOnService(this.service);
}

class _SimpleDef<T> extends BeanDefinition {
  final T Function(BeanContainer) _factory;
  _SimpleDef(this._factory);

  @override
  String get typeName => T.toString();

  @override
  dynamic create(BeanContainer container) => _factory(container);
}

class _PostConstructDef<T> extends BeanDefinition {
  final T Function(BeanContainer) _factory;
  final void Function(T) _postConstruct;

  _PostConstructDef(this._factory, this._postConstruct);

  @override
  String get typeName => T.toString();

  @override
  dynamic create(BeanContainer container) => _factory(container);

  @override
  bool get hasPostConstruct => true;

  @override
  void postConstruct(dynamic instance) => _postConstruct(instance as T);
}

class _PreDestroyDef<T> extends BeanDefinition {
  final T Function(BeanContainer) _factory;
  final void Function(T) _preDestroy;

  _PreDestroyDef(this._factory, this._preDestroy);

  @override
  String get typeName => T.toString();

  @override
  dynamic create(BeanContainer container) => _factory(container);

  @override
  bool get hasPreDestroy => true;

  @override
  void preDestroy(dynamic instance) => _preDestroy(instance as T);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late BeanContainer container;

  setUp(() {
    container = BeanContainer();
  });

  group('Basic registration and retrieval', () {
    test('register and get returns the bean', () {
      container.register<ServiceA>(_SimpleDef((_) => ServiceA()));
      final bean = container.get<ServiceA>();
      expect(bean, isA<ServiceA>());
    });

    test('get returns same instance (singleton)', () {
      container.register<ServiceA>(_SimpleDef((_) => ServiceA()));
      final a = container.get<ServiceA>();
      final b = container.get<ServiceA>();
      expect(identical(a, b), isTrue);
    });

    test('get throws BeanNotFoundException for unregistered type', () {
      expect(() => container.get<ServiceA>(), throwsA(isA<BeanNotFoundException>()));
    });

    test('has returns true for registered type', () {
      container.register<ServiceA>(_SimpleDef((_) => ServiceA()));
      expect(container.has<ServiceA>(), isTrue);
    });

    test('has returns false for unregistered type', () {
      expect(container.has<ServiceA>(), isFalse);
    });
  });

  group('Interface registration', () {
    test('register under interface and retrieve', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      final bean = container.get<Service>();
      expect(bean.name, 'A');
    });

    test('multiple implementations without @Primary throws NonUniqueBeanException', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.register<Service>(_SimpleDef((_) => ServiceB()));
      expect(() => container.get<Service>(), throwsA(isA<NonUniqueBeanException>()));
    });
  });

  group('@Primary', () {
    test('registerPrimary resolves when multiple candidates exist', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.register<Service>(_SimpleDef((_) => ServiceB()));
      container.registerPrimary<Service>(_SimpleDef((_) => ServiceC()));
      final bean = container.get<Service>();
      expect(bean.name, 'C');
    });

    test('registerPrimary works with single candidate', () {
      container.registerPrimary<Service>(_SimpleDef((_) => ServiceA()));
      final bean = container.get<Service>();
      expect(bean.name, 'A');
    });
  });

  group('@Named', () {
    test('registerNamed and getNamed', () {
      container.registerNamed<Service>('sms', _SimpleDef((_) => ServiceA()));
      container.registerNamed<Service>('email', _SimpleDef((_) => ServiceB()));
      expect(container.getNamed<Service>('sms').name, 'A');
      expect(container.getNamed<Service>('email').name, 'B');
    });

    test('getNamed throws for unknown name', () {
      expect(() => container.getNamed<Service>('unknown'), throwsA(isA<BeanNotFoundException>()));
    });

    test('getNamed returns same instance (singleton)', () {
      container.registerNamed<Service>('x', _SimpleDef((_) => ServiceA()));
      final a = container.getNamed<Service>('x');
      final b = container.getNamed<Service>('x');
      expect(identical(a, b), isTrue);
    });

    test('named beans are included in getAll', () {
      container.registerNamed<Service>('a', _SimpleDef((_) => ServiceA()));
      container.registerNamed<Service>('b', _SimpleDef((_) => ServiceB()));
      final all = container.getAll<Service>();
      expect(all.length, 2);
    });
  });

  group('getAll', () {
    test('returns all registered beans of a type', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.register<Service>(_SimpleDef((_) => ServiceB()));
      container.register<Service>(_SimpleDef((_) => ServiceC()));
      final all = container.getAll<Service>();
      expect(all.length, 3);
      expect(all.map((s) => s.name).toSet(), {'A', 'B', 'C'});
    });

    test('returns empty list for unregistered type', () {
      expect(container.getAll<Service>(), isEmpty);
    });

    test('caches instances (singleton behavior)', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      final first = container.getAll<Service>();
      final second = container.getAll<Service>();
      expect(identical(first.first, second.first), isTrue);
    });
  });

  group('replace', () {
    test('replace removes previous registrations', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.replace<Service>(_SimpleDef((_) => ServiceB()));
      final bean = container.get<Service>();
      expect(bean.name, 'B');
    });

    test('replace clears cached singleton', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.get<Service>(); // cache it
      container.replace<Service>(_SimpleDef((_) => ServiceB()));
      final bean = container.get<Service>();
      expect(bean.name, 'B');
    });
  });

  group('overrideWithInstance', () {
    test('override provides the instance directly', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.overrideWithInstance<Service>(ServiceB());
      final bean = container.get<Service>();
      expect(bean.name, 'B');
    });

    test('override before register works (pre-populate)', () {
      container.overrideWithInstance<Service>(ServiceC());
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      final bean = container.get<Service>();
      expect(bean.name, 'C'); // override wins
    });

    test('override skips @PostConstruct of original', () {
      var postConstructCalled = false;
      container.register<Service>(_PostConstructDef(
        (_) => ServiceA(),
        (_) => postConstructCalled = true,
      ));
      container.overrideWithInstance<Service>(ServiceB());
      container.get<Service>();
      expect(postConstructCalled, isFalse);
    });
  });

  group('Dependency injection', () {
    test('constructor injection resolves dependencies', () {
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      container.register<DependsOnService>(_SimpleDef((c) => DependsOnService(c.get<Service>())));
      final bean = container.get<DependsOnService>();
      expect(bean.service.name, 'A');
    });

    test('circular dependency throws', () {
      // A depends on B, B depends on A
      container.register<ServiceA>(_SimpleDef((c) {
        c.get<ServiceB>(); // triggers circular
        return ServiceA();
      }));
      container.register<ServiceB>(_SimpleDef((c) {
        c.get<ServiceA>(); // triggers circular
        return ServiceB();
      }));
      expect(() => container.get<ServiceA>(), throwsA(isA<CircularDependencyException>()));
    });
  });

  group('Lifecycle', () {
    test('@PostConstruct runs after creation', () {
      var initialized = false;
      container.register<ServiceA>(_PostConstructDef(
        (_) => ServiceA(),
        (_) => initialized = true,
      ));
      expect(initialized, isFalse);
      container.get<ServiceA>();
      expect(initialized, isTrue);
    });

    test('@PostConstruct runs only once for singletons', () {
      var count = 0;
      container.register<ServiceA>(_PostConstructDef(
        (_) => ServiceA(),
        (_) => count++,
      ));
      container.get<ServiceA>();
      container.get<ServiceA>();
      expect(count, 1);
    });

    test('@PreDestroy runs on shutdown', () async {
      var destroyed = false;
      container.register<ServiceA>(_PreDestroyDef(
        (_) => ServiceA(),
        (_) => destroyed = true,
      ));
      container.get<ServiceA>(); // trigger creation
      expect(destroyed, isFalse);
      await container.shutdown();
      expect(destroyed, isTrue);
    });
  });

  group('Prototype scope', () {
    test('registerPrototype creates new instance each time', () {
      container.registerPrototype<ServiceA>(_SimpleDef((_) => ServiceA()));
      final a = container.get<ServiceA>();
      final b = container.get<ServiceA>();
      expect(identical(a, b), isFalse);
    });
  });

  group('Module tracking', () {
    test('hasModule returns false initially', () {
      expect(container.hasModule('boot_cache'), isFalse);
    });

    test('markModule and hasModule', () {
      container.markModule('boot_cache');
      expect(container.hasModule('boot_cache'), isTrue);
    });

    test('modules are per-container (test isolation)', () {
      container.markModule('boot_cache');
      final other = BeanContainer();
      expect(other.hasModule('boot_cache'), isFalse);
    });
  });

  group('Library default bean scenario (missingBeans pattern)', () {
    test('library default loads when user provides nothing', () {
      // Simulate: library registers default InMemoryTokenStore
      // No user bean registered
      final deferred = <void Function()>[];

      // Library module: adds deferred with missingBeans check
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceA())); // default
        }
      });

      // Evaluate deferred
      for (final d in deferred.reversed) { d(); }

      expect(container.get<Service>().name, 'A');
    });

    test('user bean wins over library default', () {
      final deferred = <void Function()>[];

      // Library module: adds deferred with missingBeans check
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceA())); // default
        }
      });

      // User app: registers unconditionally
      container.register<Service>(_SimpleDef((_) => ServiceB()));

      // Evaluate deferred
      for (final d in deferred.reversed) { d(); }

      expect(container.get<Service>().name, 'B');
    });

    test('library 1 wins over library 2 (LIFO deferred order)', () {
      final deferred = <void Function()>[];

      // Library 2 (base): adds deferred first (index 0)
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceA())); // last resort
        }
      });

      // Library 1 (depends on lib 2): adds deferred second (index 1)
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceB())); // mid-priority
        }
      });

      // Evaluate in reverse (LIFO): lib 1 first, then lib 2
      for (final d in deferred.reversed) { d(); }

      expect(container.get<Service>().name, 'B'); // lib 1 wins
    });

    test('user bean wins over both libraries', () {
      final deferred = <void Function()>[];

      // Library 2: last resort default
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceA()));
        }
      });

      // Library 1: mid-priority
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceB()));
        }
      });

      // User app: unconditional
      container.register<Service>(_SimpleDef((_) => ServiceC()));

      // Evaluate deferred
      for (final d in deferred.reversed) { d(); }

      expect(container.get<Service>().name, 'C'); // user wins
    });

    test('conditional user bean + library fallback', () {
      final deferred = <void Function()>[];
      final redisEnabled = false; // simulate config

      // Library: default
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceA()));
        }
      });

      // User app: conditional on config
      if (redisEnabled) {
        container.register<Service>(_SimpleDef((_) => ServiceC()));
      }

      // Evaluate deferred
      for (final d in deferred.reversed) { d(); }

      // User bean not registered (redis disabled), library default kicks in
      expect(container.get<Service>().name, 'A');
    });

    test('conditional user bean enabled + library skipped', () {
      final deferred = <void Function()>[];
      final redisEnabled = true; // simulate config

      // Library: default
      deferred.add(() {
        if (!container.has<Service>()) {
          container.register<Service>(_SimpleDef((_) => ServiceA()));
        }
      });

      // User app: conditional on config
      if (redisEnabled) {
        container.register<Service>(_SimpleDef((_) => ServiceC()));
      }

      // Evaluate deferred
      for (final d in deferred.reversed) { d(); }

      expect(container.get<Service>().name, 'C'); // user wins
    });
  });

  group('Override in tests (bootTest pattern)', () {
    test('override before configure prevents real bean creation', () {
      // Simulate bootTest: override first, then configure
      container.overrideWithInstance<Service>(ServiceC());

      // Simulate $configure: registers definition + resolves for routes
      container.register<Service>(_SimpleDef((_) => ServiceA()));
      final resolved = container.get<Service>();

      // Override wins — ServiceA never created
      expect(resolved.name, 'C');
    });

    test('override works with dependency chain', () {
      // Override the leaf dependency
      container.overrideWithInstance<Service>(ServiceB());

      // Register dependent bean
      container.register<DependsOnService>(_SimpleDef((c) => DependsOnService(c.get<Service>())));

      final bean = container.get<DependsOnService>();
      expect(bean.service.name, 'B'); // got the override
    });
  });
}
