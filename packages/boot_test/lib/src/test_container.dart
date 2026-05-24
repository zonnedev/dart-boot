import 'package:boot/boot.dart';

/// Test-friendly container that supports bean overrides.
class TestContainer {
  final BeanContainer _container = BeanContainer();

  /// Register a bean definition.
  void register(BeanDefinition definition) => _container.register(definition);

  /// Override a bean with a direct instance.
  void override<T extends Object>(T instance) =>
      _container.overrideWithInstance<T>(instance);

  /// Override a bean with a factory.
  void overrideFactory<T>(BeanDefinition definition) =>
      _container.replace<T>(definition);

  /// Retrieve a bean.
  T get<T>() => _container.get<T>();

  /// Retrieve all beans of a type.
  List<T> getAll<T>() => _container.getAll<T>();

  /// Retrieve a named bean.
  T getNamed<T>(String name) => _container.getNamed<T>(name);

  /// Check if a bean type is registered.
  bool has<T>() => _container.has<T>();

  /// Access the underlying container.
  BeanContainer get container => _container;

  /// Reset all singletons and overrides.
  Future<void> reset() => _container.shutdown();
}
