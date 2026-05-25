import 'bean_definition.dart';
import 'exceptions.dart';
import 'method_interceptor.dart';

/// Lightweight DI container populated by generated code at startup.
class BeanContainer {
  final _definitions = <Type, List<BeanDefinition>>{};
  final _namedDefinitions = <String, BeanDefinition>{};
  final _namedTypes = <String, Type>{};
  final _singletons = <Type, Object>{};
  final _namedSingletons = <String, Object>{};
  final _allSingletons = <BeanDefinition, Object>{};
  final _creating = <Type>{};
  final _destroyCallbacks = <dynamic Function()>[];
  final _primaryTypes = <Type>{};
  final _prototypeTypes = <Type>{};
  final _interceptors = <Type, List<MethodInterceptor>>{};
  final _pendingInits = <Future<void>>[];
  final _loadedModules = <String>{};

  /// Register a bean definition. Multiple beans of the same type can coexist.
  void register<T>(BeanDefinition definition) {
    _definitions.putIfAbsent(T, () => []).add(definition);
  }

  /// Register a prototype-scoped bean (new instance each time).
  void registerPrototype<T>(BeanDefinition definition) {
    _definitions.putIfAbsent(T, () => []).add(definition);
    _prototypeTypes.add(T);
  }

  /// Register a named bean definition.
  void registerNamed<T>(String name, BeanDefinition definition) {
    _namedDefinitions[name] = definition;
    _namedTypes[name] = T;
    // Also register by type for getAll<T>()
    _definitions.putIfAbsent(T, () => []).add(definition);
  }

  /// Register as primary (preferred when multiple candidates exist).
  void registerPrimary<T>(BeanDefinition definition) {
    _definitions.putIfAbsent(T, () => []).add(definition);
    _primaryTypes.add(T);
  }

  /// Replace all beans of a type with this one (@Replaces).
  void replace<T>(BeanDefinition definition) {
    _definitions[T] = [definition];
    _singletons.remove(T);
  }

  /// Retrieve a bean by type.
  /// - 1 candidate → returns it
  /// - Multiple + @Primary → returns primary
  /// - Multiple + no primary → throws NonUniqueBeanException
  T get<T>() {
    if (_prototypeTypes.contains(T)) {
      final def = _resolve<T>();
      final instance = def.create(this) as T;
      if (def.hasPostConstruct) def.postConstruct(instance);
      return instance;
    }

    final cached = _singletons[T];
    if (cached != null) return cached as T;

    final definition = _resolve<T>();

    if (_creating.contains(T)) {
      throw CircularDependencyException([..._creating, T].toList());
    }

    _creating.add(T);
    try {
      final instance = definition.create(this) as T;
      _singletons[T] = instance as Object;

      if (definition.hasPostConstruct) {
        definition.postConstruct(instance);
      }
      if (definition.hasPostConstructAsync) {
        _pendingInits.add(definition.postConstructAsync(instance));
      }
      if (definition.hasPreDestroy) {
        _destroyCallbacks.add(() => definition.preDestroy(instance));
      }
      if (definition.hasPreDestroyAsync) {
        _destroyCallbacks.add(() => definition.preDestroyAsync(instance));
      }

      return instance;
    } finally {
      _creating.remove(T);
    }
  }

  /// Resolve which definition to use for type T.
  BeanDefinition _resolve<T>() {
    final defs = _definitions[T];
    if (defs == null || defs.isEmpty) throw BeanNotFoundException(T);
    if (defs.length == 1) return defs.first;

    // Multiple candidates — check for @Primary
    if (_primaryTypes.contains(T)) {
      return defs.last; // Primary is always added last via registerPrimary
    }

    throw NonUniqueBeanException(T, defs.map((d) => d.beanType.toString()).toList());
  }

  /// Retrieve all beans of a type.
  List<T> getAll<T>() {
    final defs = _definitions[T];
    if (defs == null || defs.isEmpty) return [];
    return defs.map((d) {
      // Check if already cached (singleton)
      final cached = _allSingletons[d];
      if (cached != null) return cached as T;

      final instance = d.create(this) as T;
      _allSingletons[d] = instance as Object;
      if (d.hasPostConstruct) d.postConstruct(instance);
      if (d.hasPreDestroy) {
        _destroyCallbacks.add(() => d.preDestroy(instance));
      }
      return instance;
    }).toList();
  }

  /// Retrieve all bean definitions for a type (with their annotation metadata).
  List<BeanDefinition> getDefinitions<T>() => _definitions[T] ?? [];

  /// All registered bean definitions (for runtime scanning).
  Iterable<MapEntry<Type, List<BeanDefinition>>> get allDefinitions => _definitions.entries;

  /// Retrieve a named bean.
  T getNamed<T>(String name) {
    final cached = _namedSingletons[name];
    if (cached != null) return cached as T;

    final definition = _namedDefinitions[name];
    if (definition == null) {
      throw BeanNotFoundException(T, name: name);
    }

    final instance = definition.create(this) as T;
    _namedSingletons[name] = instance as Object;

    if (definition.hasPostConstruct) {
      definition.postConstruct(instance);
    }
    if (definition.hasPreDestroy) {
      _destroyCallbacks.add(() => definition.preDestroy(instance));
    }

    return instance;
  }

  /// Check if a bean type is registered.
  bool has<T>() => _singletons.containsKey(T) || (_definitions.containsKey(T) && _definitions[T]!.isNotEmpty);

  bool hasNamed<T>(String name) =>
      _namedDefinitions.containsKey(name) && _namedTypes[name] == T;

  /// Check if a library module has been loaded (per-container, test-safe).
  bool hasModule(String name) => _loadedModules.contains(name);

  /// Mark a library module as loaded.
  void markModule(String name) => _loadedModules.add(name);

  /// Override with a direct instance (for testing).
  void overrideWithInstance<T extends Object>(T instance) {
    _singletons[T] = instance;
  }

  /// Register an interceptor for an advice annotation type.
  void registerInterceptor(Type adviceAnnotation, MethodInterceptor interceptor) {
    _interceptors.putIfAbsent(adviceAnnotation, () => []).add(interceptor);
  }

  /// Get all interceptors for an advice annotation.
  List<MethodInterceptor> getInterceptors(Type adviceAnnotation) {
    return _interceptors[adviceAnnotation] ?? const [];
  }

  /// Wait for all async @PostConstruct methods to complete.
  Future<void> ready() async {
    await Future.wait(_pendingInits);
    _pendingInits.clear();
  }

  /// Call all @PreDestroy callbacks (sync and async).
  Future<void> shutdown() async {
    for (final callback in _destroyCallbacks.reversed) {
      final result = callback();
      if (result is Future) await result;
    }
    _destroyCallbacks.clear();
    _singletons.clear();
    _namedSingletons.clear();
  }
}
