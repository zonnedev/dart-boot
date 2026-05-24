import 'bean_container.dart';

/// Compile-time generated bean definition.
abstract class BeanDefinition {
  /// The bean type name (used for debugging only).
  String get typeName;

  /// Create the bean instance, resolving dependencies from the container.
  dynamic create(BeanContainer container);

  void postConstruct(dynamic instance) {}
  Future<void> postConstructAsync(dynamic instance) async {}
  void preDestroy(dynamic instance) {}
  Future<void> preDestroyAsync(dynamic instance) async {}

  bool get hasPostConstruct => false;
  bool get hasPostConstructAsync => false;
  bool get hasPreDestroy => false;
  bool get hasPreDestroyAsync => false;
}
